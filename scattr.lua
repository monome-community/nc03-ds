-- 'scattr' - by raja
-- based on "nc03 snippet: 
-- replace jumble w/ sequins"
-- enc2 - selects UI, 
-- enc3 - changes things
-- k3 - start/stop play
-- k2 - changes things
--  specific to context...
--  most often 'stutter'
--  speed(jumps to UISelection)
-- enc1 - jitters each
-- instrument/seq's stutter
-- while the 'Seq#' is selected

sc_fn = include 'lib/sc_helpers'
frm = require 'formatters'
lfo = require 'lfo' 

s = require 'sequins'
pos = 0; stutt = 0; kit = 1; sel = 0; stpp = 0; seqnum = 1; copast = 0; delt = 0.2; rnd = 0; count = 0; countm = 18; p = 0
kitz = {'default-1', 'default-2', 'fltr-amod-eq', 'fm-lite', 'heavy', 'mods-1', 'mods-2', 'verb-long', 'verb-short'}
seqlengths = {14,10,18,10,8,9}
seqlens = {14,10,18,10,8,9}
function set_tempo(tmp) params:set("clock_tempo",tmp) end
params:add{type="number", id="Tempo", min = 1, max = 300, default = 88, action = function(x) set_tempo(x) end}
function init()
  sc_fn.move_samples_into_audio()
  softcut_offsets = {1,102,1,102,204,204}
  softcut_buffers = {1,1,2,2,1,2}
  max_sample_duration = 100
  samples = {}

  params:add_separator("VOICES")

  for i = 1,6 do
    
    samples[i] = {
      sample_count = 0,
      rate_offset = 0,
      semitone_offset = 0,
      reverse = 1,
      pitch_control = 0
    }
    
    softcut.buffer_clear()
    softcut.buffer(i, softcut_buffers[i])
    softcut.enable(i,0)
    softcut.play(i,1)
    softcut.loop(i,0)
    softcut.fade_time(i,0.001)
    softcut.loop_start(i,softcut_offsets[i])
    softcut.loop_end(i,softcut_offsets[i]+1) 
    softcut.position(i,softcut_offsets[i]+1) 
    softcut.rate(i,1)
    softcut.pan_slew_time(i,0.01)
    softcut.level_slew_time(i,0.01)
    
    params:add_group("voice_"..i, "voice ["..i.."]", 15)

    params:add_separator("voice_"..i.."_controls", "voice controls")

    params:add_file("voice "..i.." sample", "load sample", _path.audio)
    params:set_action("voice "..i.." sample",
      function(file)
        if file ~= _path.audio then
          sc_fn.file_callback(file,i)
        elseif file == _path.audio then
        end
      end
    )

    params:add_text("voice "..i.." sample folder text", "", "")
    params:hide("voice "..i.." sample folder text")

    params:add{
      type = 'trigger',
      id = "voice "..i.." clear",
      name = "clear samples",
      action =
        function()
          sc_fn.clear_voice(i)
        end
    }
    
    params:add{
      type = "control",
      id = "level_"..i,
      name = "level ["..i.."]",
      controlspec = controlspec.new(0, 2.5, 'lin', 0.01, 1, nil, 1/250, nil),
      formatter = function(param) return(util.round(param:get() * 100,1).."%") end,
      action = function(x) softcut.level(i,x) end
    }
    
    params:add{
      type = "control",
      id = "pan_"..i,
      name = "pan ["..i.."]",
      controlspec = controlspec.new(-1, 1, 'lin', 0.01, 0, nil, 1/200, nil),
      formatter = frm.bipolar_as_pan_widget,
      action = function(x) softcut.pan(i,x) end
    }

    params:add{
      type = "control",
      id = "semitone_offset_"..i,
      name = "semitone offset ["..i.."]",
      controlspec = controlspec.new(-48, 48, 'lin', 0.01, 0, 'st', 1/96, nil),
      action = function(x)
        samples[i].rate_offset = math.pow(0.5, -x / 12)
        samples[i].semitone_offset = x
        softcut.rate(i,sc_fn.get_total_pitch_offset(i, samples[i].mode))
      end
    }

    params:add{
      type = "control",
      id = "pitch_control_"..i,
      name = "pitch control ["..i.."]",
      controlspec = controlspec.new(-25, 25, 'lin', 0.01, 0, nil, 1/500, nil),
      formatter = function(param) return(util.round(param:get(),0.01).."%") end,
      action = function(x)
        samples[i].pitch_control = x/100
        softcut.rate(i,sc_fn.get_total_pitch_offset(i, samples[i].mode))
      end
    }

    params:add{
      type = "binary",
      id = "reverse_"..i,
      name = "reverse ["..i.."]",
      behavior = "toggle",
      action = function(x)
        samples[i].reverse = x == 1 and -1 or 1
        softcut.rate(i,sc_fn.get_total_pitch_offset(i, samples[i].mode))
      end
    }

    local filter_bands = {
      {id = "post_filter_lp", name = "lowpass"},
      {id = "post_filter_hp", name = "highpass"},
      {id = "post_filter_bp", name = "bandpass"},
      {id = "post_filter_dry", name = "dry"}
    }
    for k,v in pairs(filter_bands) do
      params:add{
        type = "control",
        id = v.id.."_"..i,
        name = v.name.." ["..i.."]",
        controlspec = controlspec.new(0, 1, 'lin', 0.01, v.name == "dry" and 1 or 0, nil, nil, nil),
        formatter = function(param) return(util.round(param:get() * 100,1).."%") end,
        action = function(x) softcut[v.id](i,x) end
      }
    end
    
    params:add{
      type = "control",
      id = "post_filter_fc_"..i,
      name = "filter cutoff ".."["..i.."]",
      controlspec = controlspec.new(10, 12000, 'exp', 0.01, 12000, 'hz', nil, nil),
      action = function(x) softcut.post_filter_fc(i,x) end
    }

    params:add{
      type = "control",
      id = "post_filter_rq_"..i,
      name = 'filter q '.."["..i.."]",
      controlspec = controlspec.new(0, 100, 'lin', 0.01, 0, nil, nil, nil),
      formatter = function(param) return(util.round(param:get(),1).."%") end,
      action = function(x)
        local scaled = util.linlin(0,100,2.0,0.001,x)
        softcut.post_filter_rq(i,scaled)
      end
    }
    
    params:bang()

  end
  
  sc_fn.load_kit(kitz[kit])
  
  play_seq = {}

  play_seq[1] = s{1,0,0,0,0,0,1,0,0,0,0,0,0,0}
  play_seq[2] = s{0,1,0,0,0,0,1,1,0,0}
  play_seq[3] = s{0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0}
  play_seq[4] = s{1,0,1,0,0,1,0,1,0,0}
  play_seq[5] = s{1,0,0,0,1,0,0,0}
  play_seq[6] = s{0,0,1,0,0,0,0,1,0}
  
  lfos = {post_filter_fc={}, pan={}}
  
  for i = 1,6 do
    
    lfos.post_filter_fc[i] = lfo:add{
      min = 20,
      max = 12000,
      action = function(scaled,raw)
        params:set('post_filter_fc_'..i, scaled)
      end
    }
    
    lfos.pan[i] = lfo:add{
      min = 0-((i-1)*0.16),
      max = 0+((i-1)*0.16),
      action = function(scaled,raw)
        params:set('pan_'..i, scaled)
      end
    }

    for k,v in pairs(lfos) do
      lfos[k][i]:set('ppqn', 48) -- reduce resolution (no need for 96ppqn here)
      lfos[k][i]:set('period', math.random(15)*0.5) -- set clock periods to random values
      lfos[k][i]:start() -- start each LFO
    end
    
    if i ~= 1 then -- keep the kick unfiltered
      params:set('post_filter_dry_'..i,0) -- no dry signal
      local filters = {'lp','hp','bp'} -- index our filter types
      -- we'll turn a random filter type up to 1 (== 100%) with each script load:
      params:set('post_filter_'..filters[math.random(3)]..'_'..i,1)
      -- let's randomly set the filter q:
      params:set('post_filter_rq_'..i,math.random(90))
    end
    
  end
  
  screen_dirty = true
  screen_redraw = metro.init(draw_screen, 1/15, -1)
  screen_redraw:start()
  
end

function start_song()
  song = clock.run(
    function()
      while true do
        clock.sync(1/8) -- cycle through at 1/32nd notes
        count = count + 1
        count = count % countm
        if count == 0 then
          for i = 1,#play_seq do
            play_seq[i]:reset()
          end
        end
        for i = 5,6 do              -- 'copast' is just 'delay' on/off
          softcut.loop(i,copast) 
          softcut.rec(i,copast)
          softcut.pre_level(i,copast*0.7)
          softcut.rec_level(i,copast*0.8)
          softcut.level_cut_cut(1,i,copast)
          softcut.level_cut_cut(2,i,copast)
          softcut.level_cut_cut(3,i,copast)
          softcut.level_cut_cut(4,i,copast)
        end
        
        if copast==1 then  -- with delay on
          for i = 5,6 do
            softcut.loop_start(i,300)
            softcut.loop_end(i,300+(delt*0.5))
            softcut.position(i,300)
            delt = util.wrap(delt + (math.random(100)*((((math.random(2)-1)*2)-1)*0.0001)),0.0001,0.2)
            screen_dirty = true
          end
        end
        if rnd==1 then       -- main RANDomizer
          if count == 0 then
            kit = math.random(9)
            sc_fn.load_kit(kitz[kit])
            for i = 1,6 do
              softcut.loop(i,math.random(2)-1)
            end
            stutt = math.random(2)
            stpp = math.random(10)
            pos = math.random(100)*0.5
            if math.random(2)>1 then copast = 1-copast end
            screen_dirty = true
          end
        end
        
        if p == 0 then                              -- at downbeat 1/16th notes
          for i = 1,#play_seq do
            local step_value = play_seq[i]()
            if step_value == 1 then
              sc_fn.play_slice(i,1)
            end
          end
          for i = 1,(copast*2)+4 do
            if stutt==1 then
              softcut.loop_end(i,softcut_offsets[i]+(pos*0.002))
              softcut.loop(i,math.random(2))
            else
              if sel ~= 5 then
                softcut.loop(i,0)
              end
            end
          end
          for i = 1,(copast*2)+4 do
              if stpp>0 then
              if math.random(stpp)>1 then
              softcut.position(i,50)
              end
              end
          end
          p = 1
        elseif p == 1 then                        -- at syncopated 1/16th notes
            for i = 1,(copast*2)+4 do
              if stpp>0 then
              if math.random(stpp)>1 then
              softcut.position(i,50)
              end
              end
            end
          p = 0
        end
      end
  end
  )
end

function stop_song()
  clock.cancel(song)
  song = nil
  for i = 1,#play_seq do
    play_seq[i]:reset()
  end
end

function enc(n,d)
  if n == 3 then
    if sel == 1 then
      kit = util.wrap(kit+d,1,9)
      sc_fn.load_kit(kitz[kit])
    elseif sel == 2 then
      countm = util.wrap(countm+d,1,96)  
    elseif sel == 3 then
      pos = util.wrap(pos+d,0,100)
      stutt = 1
    elseif sel == 4 then 
      stpp = util.clamp(stpp+d,0,10)
    elseif sel == 5 then 
      seqnum = util.wrap(seqnum+d,1,6)
    elseif sel == 7 then
      copast = 1-copast
    elseif sel == 8 then
      delt = delt+(d*0.002)
    elseif sel == 9 then
      rnd = 1 - rnd
    elseif sel == 10 then
      params:set("Tempo",params:get("Tempo")+d)
    end
  elseif n == 2 then
    sel = util.wrap(sel+d,1,10)
  elseif n == 1 then
    if sel == 5 then
        softcut.loop_end(seqnum,softcut_offsets[seqnum]+(math.random(1000)*0.0005))
        softcut.loop(seqnum,1)
    else
      for i = 1,6 do
        softcut.loop_end(i,softcut_offsets[i]+100)
        softcut.loop(i,0)
      end
    end
  end
  screen_dirty = true
end

function key(n,z)
  if n == 3 and z == 1 then
    if sel == 6 then
      copast = 1-copast
      else
      if song == nil then
        start_song()
      else
        stop_song()
        for i = 1,6 do
        softcut.loop(i,0)
        end
      end
    end
  elseif n == 2 and z == 1 then
    if sel == 5 then                    -- if "Seq#" is selected, k2 randomizes '0's towards '1's
      for i = 1,seqlengths[seqnum] do
        if play_seq[seqnum][i] == 0 then
          play_seq[seqnum][i] = math.random(2)-1
        end
      end
    elseif sel==6 then          -- if 'rand' is selected, k2 randomizes both '0's and '1's to their opposite(random-selectively)
      for i = 1,seqlengths[seqnum] do
      play_seq[seqnum][i] = math.random(2)-1
      end
    else                    --else if nothing within 'Seq#' row-of-UI is selected, k2 turns 'Stutter' on/off
      stutt = 1-stutt         --and jumps UI selection to relate enc3 to 'Stutter' changes
      sel = 3
    end
  end
  screen_dirty = true
end
                                                     --[[SCREEN STUFF]]--
function draw_screen()
  if screen_dirty then
    redraw()
    screen_dirty = false
  end
end

function redraw()
  screen.clear()
  screen.move(10,10)
  if sel == 1 then
    screen.level(15)
    else screen.level(5)
  end
  screen.text("Kit: "..kitz[kit])
  if sel == 2 then
    screen.level(15)
    else screen.level(5)
  end
  screen.move(88,20)
  screen.text("CycLn:"..countm)
  if sel == 3 then
    screen.level(15)
    else screen.level(5)
  end
  screen.move(10,20)
  screen.text("Stutter: "..pos.."%")
  if stutt==1 then screen.text("on") else screen.text("off") end
  if sel == 4 then
    screen.level(15)
    else screen.level(5)
  end
  screen.move(10,30)
  screen.text("Stoppage: "..(stpp*10.0).."%")
  if sel == 5 then
    screen.level(15)
    else screen.level(5)
  end
  screen.move(10,40)
  screen.text("Seq#"..seqnum..":")
  screen.move(10,50)
  for i = 1,seqlengths[seqnum] do
  screen.text(play_seq[seqnum][i])
  end
  if sel == 6 then
    screen.level(15)
    else screen.level(5)
  end
  screen.move(88,50)
  screen.text("rand")
  if sel == 7 then
    screen.level(15)
    else screen.level(5)
  end
  screen.move(10,60)
  if copast==1 then screen.text("delon") else screen.text("deloff") end
  if sel == 8 then
    screen.level(15)
    else screen.level(5)
  end
  screen.move(40,60)
  screen.text("delt: "..delt)
  if sel == 9 then
    screen.level(15)
    else screen.level(5)
  end
  screen.move(88,10)
  if rnd==1 then screen.text("RAND") else screen.text("Rand") end
  if sel == 10 then
    screen.level(15)
    else screen.level(5)
  end
  screen.move(88,32)
  screen.text("Tempo:")
  screen.move(88,40)
  screen.text(params:string("Tempo"))
  screen.update()
end
