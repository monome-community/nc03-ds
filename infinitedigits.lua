-- wards
-- https://github.com/monome-community/nc03-ds
-- https://llllllll.co/t/57649
-- construct an evolving expression of
-- rhythmic time using provided synth drum
-- samples, the new lfo library, and sequins.

s=require("sequins")
lattice=require("lattice")
_lfos = require 'lfo'

debounce_sequins=0
k2on=false
global_divisions={1/32,1/24,1/16,1/12,1/8,1/6,1/2}
global_division_options={}
for _, div in ipairs(global_divisions) do
  table.insert(global_division_options,"1/"..math.floor(1/div))
end
global_beats={0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}

function setup_clock()
  -- use lattice for the clock
  lat=lattice:new()
  for divisioni, division in ipairs(global_divisions) do 
    pattern=lat:new_pattern{
      action=function(v)
        global_beats[divisioni]=global_beats[divisioni]+1
        if division==1/16 then 
          if k2on then
            params:delta("sample",1)
          end
          if debounce_sequins>0 then
            debounce_sequins=debounce_sequins-1
            if debounce_sequins==0 then
              setup_sequins()
            end
          end
        end
        if seqs~=nil then
          for i=1,6 do
            if divisioni==params:get(i.."division") then 
              local seq=seqs[i]()
              if next(seq)~=nil then
                play(i,seq.sample,seq.len*seq.direction)
              end
            end
          end
        end
        if division==1/16 then 
          redraw()
        end
      end,
      division=division,
    }
    
  end
  lat:start()
end

function math.sign(x)
  if x<0 then
    return-1
  elseif x>0 then
    return 1
  else
    return 0
  end
end

function setup_sequins()
  print("setup_sequins")
  if seqs==nil then
    seqs={}
    for i=1,6 do
      -- empty sequins
      table.insert(seqs,s{})
    end
  end
  hptns={}
  for i=1,6 do
    local ptns={}
    local ptn={}
    for sn=1,32 do
      local num=params:get(i.."_"..sn)
      -- get sample number from the "10s"
      local sample_num=math.floor(math.abs(num)/10)
      -- get the start from a "2" remainder
      local is_start=math.abs(num)%10==2
      -- get the continuation from a "1" remainder
      local is_continue=math.abs(num)%10==1
      -- get the direction from the sign
      local direction=math.sign(num)

      -- check if its a start, add it to the pattern
      if is_start or num==0 then
        if next(ptn)~=nil then
          ptn.len=ptn.stop-ptn.start+1 -- +1
          table.insert(ptns,ptn)
        end
        if is_start then
          ptn={start=sn,stop=sn,sample=sample_num,direction=direction}
        else
          ptn={}
        end
      elseif is_continue and next(ptn)~=nil then
        ptn.stop=sn
      end
    end
    table.insert(hptns,ptns)
  end

  -- create sequins from this hptn
  for i=1,6 do
    local seq={}
    for sn=1,32 do
      table.insert(seq,{})
    end
    local last=1
    for _,p in ipairs(hptns[i]) do
      if p.start~=nil then
        seq[p.start]=p
        if p.stop>last then
          last=p.stop
        end
      end
    end
    local load_seq={}
    for ii=1,last do
      table.insert(load_seq,seq[ii])
    end
    seqs[i]:settable(load_seq)
    seqs[i].ix=global_beats[params:get(i.."division")]%seqs[i].length+1
  end
end

function setup_parameters()
  -- each parameter composed of 32 beats
  for voice=1,6 do
    for sn=1,32 do
      params:add_number(voice.."_"..sn,"beat "..sn,-20000,20000)
      -- hide the parameters so you don't SEE
      params:hide(voice.."_"..sn)
      -- set an action to reload pattern into sequins
      params:set_action(voice.."_"..sn,function(x)
        debounce_sequins=2
      end)
    end
  end

end

function setup_softcut()
  -- reset softcut
  softcut.reset()

  -- create a for loop to initate the softcut voices
  for i=1,softcut.VOICE_COUNT do
    -- which buffer we are using
    softcut.buffer(i,1)
    -- enable voice
    softcut.enable(i,1)
    -- disable playing
    softcut.play(i,0)
    -- disable looping
    softcut.loop(i,0)
    -- set crossfade time
    softcut.fade_time(i,0.02)
    -- set rate
    softcut.rate(i,1)
    -- set pan
    softcut.pan(i,0)
    -- set slews
    softcut.pan_slew_time(i,0.01)
    softcut.level_slew_time(i,0.01)
    softcut.rate_slew_time(i,0.0)

    -- for each voice, make a parameter to adjust it
    -- (copy things from sc_params.lua)
    params:add_group("VOICE "..i,11)

    params:add_option(i.."division","division",global_division_options,3)
    params:add{
      type="control",
      id=i.."level",
      name="level",
      controlspec=controlspec.new(0,2.5,'lin',0.01,1,0.01/2.5),
      formatter=function(param) return(util.round(param:get()*100,1).."%") end,
      action=function(x) softcut.level(i,x) end,
    }

    params:add{
      type="control",
      id=i.."pan",
      name="pan",
      controlspec=controlspec.new(0,2.5,'lin',0.01,1,0.01/2.5),
      -- formatter=frm.bipolar_as_pan_widget,
      action=function(x) softcut.pan(i,x) end,
    }

    params:add{
      type="control",
      id=i.."rate",
      name="rate ["..i.."]",
      controlspec=controlspec.new(-2,2,'lin',0.125,1,'st',0.125/4),
      action=function(x)
        local rev=params:get(i.."reverse")==0 and 1 or-1
        local rate=params:get(i.."rate")*rev
        softcut.rate(i,rate)
      end
    }

    params:add{
      type="binary",
      id=i.."reverse",
      name="reverse ["..i.."]",
      behavior="toggle",
      action=function(x)
        local rev=params:get(i.."reverse")==0 and 1 or-1
        local rate=params:get(i.."rate")*rev
        softcut.rate(i,rate)
      end
    }

    local filter_bands={
      {id="post_filter_lp",name="lowpass"},
      {id="post_filter_hp",name="highpass"},
      {id="post_filter_bp",name="bandpass"},
    {id="post_filter_dry",name="dry"}}
    for k,v in pairs(filter_bands) do
      params:add{
        type="control",
        id=v.id.."_"..i,
        name=v.name.." ["..i.."]",
        controlspec=controlspec.new(0,1,'lin',0.01,v.name=="lowpass" and 1 or 0,nil,nil,nil),
        formatter=function(param) return(util.round(param:get()*100,1).."%") end,
        action=function(x) softcut[v.id](i,x) end
      }
    end

    params:add{
      type="control",
      id="post_filter_fc_"..i,
      name="filter cutoff ".."["..i.."]",
      controlspec=controlspec.new(10,12000,'exp',0.01,12000,'hz',nil,nil),
      action=function(x) softcut.post_filter_fc(i,x) end
    }

    params:add{
      type="control",
      id="post_filter_rq_"..i,
      name='filter q '.."["..i.."]",
      controlspec=controlspec.new(0,100,'lin',0.01,0,nil,nil,nil),
      formatter=function(param) return(util.round(param:get(),1).."%") end,
      action=function(x)
        local scaled=util.linlin(0,100,2.0,0.001,x)
        softcut.post_filter_rq(i,scaled)
      end
    }
  end
  
  
  -- IMPORTANT! set your LFO's 'min' and 'max' *before* adding params, so they can scale appropriately:
  for i=1,6 do 
    local lfo=_lfos:add{min = 200, max = 3000, period=math.random(8,32),action=function(scaled,raw)
      params:set("post_filter_fc_"..i,scaled)
      end
    }
    lfo:start()
    local lfodiv=_lfos:add{min =1, max = 5, period=math.random(8,32),action=function(scaled,raw)
      params:set(i.."division",scaled)
      end
    }
    lfodiv:start()
    local lforate=_lfos:add{min =0.5, max = 1, period=math.random(12,64),action=function(scaled,raw)
      params:set(i.."rate",scaled)
      end
    }
    lforate:start()
    local lfolevel=_lfos:add{min =0.0, max = 0.5, period=math.random(12,64),action=function(scaled,raw)
      params:set(i.."level",scaled)
      end
    }
    lfolevel:start()
    local lfopan=_lfos:add{min =-1.0, max = 1.0, period=math.random(12,80),action=function(scaled,raw)
      params:set(i.."pan",scaled)
      end
    }
    lfopan:start()
  end
  local lfo=_lfos:add{min = clock.get_tempo()-10, max = clock.get_tempo()+10, period=math.random(8,32),action=function(scaled,raw)
    params:set("clock_tempo",scaled)
    end
  }
  lfo:start()
  -- local bpm_lfo = _lfos:add{min = clock.get_tempo()-10, max = clock.get_tempo()+10, period=math.random(6,16)}
  -- local num_lfos = 2
  -- -- 14 parameters for LFOs + 1 separator for each:
  -- params:add_group('LFOs',num_lfos*15)
  -- -- now we can add our params
  -- cutoff_lfo:add_params('cutoff_lfo', 'cutoff')
  -- cutoff_lfo:set('action', function(scaled, raw) engine.cutoff(scaled) screen_dirty = true end)
    
  
  
  params:add_number("selected","selected",1,6,1)
  params:add_number("beat_start","start",0,33,1)
  params:add_number("beat_length","beat_length",-32,32,1)
  params:hide("selected")
  params:hide("beat_start")
  params:hide("beat_length")

  params:bang()
end

function setup_samples()
  -- clear the buffer
  softcut.buffer_clear()

  -- create an empty table
  -- GLOBAL table
  samples={}

  -- copy from sc_helpers.lua
  local paths={
    '01-bd',
    '02-sd',
    '03-tm',
    '04-cp',
    '05-rs',
    '06-cb',
    '07-hh',
  }

  -- loop through each path
  for _,folder in ipairs(paths) do
    -- load the folder
    folder=_path.audio.."nc03-ds/"..folder

    -- scan the folder
    local all_files=util.scandir(folder)

    -- get only audio files
    local clean_wavs={}
    for _,fname in ipairs(all_files) do
      -- get pathname filename ext
      local pathname,filename,ext=string.match(fname,"(.-)([^\\/]-%.?([^%.\\/]*))$")
      -- get the full path
      local path=folder.."/"..filename
      -- check if its an audio file
      if string.match(ext,"wav") or string.match(ext,"flac") or string.match(ext,"aiff") then
        if string.find(filename,"long") or string.find(filename,"bd_default") then
          table.insert(clean_wavs,path)
        end
      end
    end

    -- collect informaton on each sample
    for _,path in ipairs(clean_wavs) do
      -- get file info
      local ch,len,rate=audio.file_info(path)
      -- get filename
      local pathname,filename,ext=string.match(path,"(.-)([^\\/]-%.?([^%.\\/]*))$")
      local rendered={}
      for ii=1,128 do
        table.insert(rendered,0)
      end
      table.insert(samples,{
        path=path,
        len=len,
        duration=len/48000,
        filename=filename,
        rendered=rendered,
      })
    end

    -- lets actually load the files now into softcut
    -- figure out the total duration of all the samples
    local total_duration=0
    for _,sample in ipairs(samples) do
      total_duration=total_duration+sample.duration
    end
    -- lets figure out the buffer time we have left
    local time_remaining=softcut.BUFFER_SIZE-total_duration-6
    -- and now we can proportion time to each sample
    local time_per_sample=time_remaining/#samples

    -- lets load in each sample into a position
    -- spaced by the calculated time
    local pos=3
    for i,sample in ipairs(samples) do
      print("loading",sample.path,"into pos",pos)
      softcut.buffer_read_mono(sample.path,0,pos,-1,1,1,0,1)
      -- save position of the sample
      samples[i].pos=pos-0.005
      -- iterate the position by the size of the sample
      -- and the time per sample
      pos=pos+sample.duration+time_per_sample
    end
  end

  params:add_number("sample","sample",1,#samples,1,function(param) return samples[param:get()].filename end,true)
  params:hide("sample")
  -- that's it! all samples are loaded
end

function play(voice,samplei,sn)
  -- sn: sixteenth notes to PLAY
  -- if negative, start from the start reversed
  -- figure out the start+end position
  local pos={start=0,stop=1} -- in seconds
  if sn>0 then
    pos.start=samples[samplei].pos
    pos.stop=pos.start+clock.get_beat_sec()/4*math.abs(sn)
  elseif sn<0 then
    pos.stop=samples[samplei].pos
    pos.start=pos.stop+clock.get_beat_sec()*math.abs(sn)*4*global_divisions[params:get(voice.."division")]
  else
    -- sn cannot be 0
    do return end
  end
  if pos.start<0 then
    pos.start=0
  end

  -- setup the loop positions
  -- print("play",voice,samplei,sn,pos.start,pos.stop)
  local rate=params:get(voice.."rate")*(sn>0 and 1 or-1)
  -- rate=rate*global_divisions[params:get(voice.."division")]*16
  softcut.rate(voice,rate)
  softcut.loop_start(voice,(sn>0 and pos.start-2 or pos.stop))
  softcut.loop_end(voice,(sn>0 and pos.stop or pos.start+2))
  softcut.position(voice,pos.start)
  softcut.play(voice,1)
end

-- rendering function
function setup_renders()
  -- local samplei=1
  softcut.event_render(function(ch,start,sec_per_sample,s)
    local maxval=0
    for i,v in ipairs(s) do
      if v>maxval then
        maxval=math.abs(v)
      end
    end
    for i,v in ipairs(s) do
      s[i]=s[i]/maxval
    end
    print("rendered pos",start)
    for samplei,_ in ipairs(samples) do
      if math.abs(samples[samplei].pos-start)<1 then
        print("rendered",samplei)
        samples[samplei].rendered=s
        do return end
      end
    end
  end)
  for ii=1,#samples do
    softcut.render_buffer(1,samples[ii].pos,samples[ii].duration,128)
  end
end

-- norns basic functions
function init()
  setup_softcut()
  setup_samples() -- load in the samples to softcut
  setup_parameters() -- load parameters for patterns
  setup_sequins() -- load the sequins stuff
  setup_clock() -- setup lattice
  setup_renders()
  print("hello, world")

    params:set("clock_tempo",120)

  -- softcut.event_phase(function(i,x)
  --   if i==1 then
  --     print(x)
  --   end
  -- end)
  -- softcut.poll_start_phase()
  -- params:set("1_12",22)
  -- params:set("1_13",22)
  -- params:set("1_1",22)
  -- params:set("1_2",21)
  -- params:set("1_3",22)
  -- params:set("1_4",21)
  -- params:set("1_16",-32)
  -- params:set("1_17",-31)
  -- params:set("1_18",-31)
  -- params:set("1_19",-31)
  -- params:set("1_24",302)
  -- params:set("1_25",301)
  -- params:set("1_26",301)
  -- params:set("1_27",301)
end

function get_selected()
  local selected=params:get("selected")
  local current=params:get("beat_start")
  local current_width=math.abs(params:get("beat_length"))
  if params:get("beat_length")<0 then
    current=current-current_width+1
  end
  while current<=0 do
    current=current+1
    current_width=current_width-1
  end
  return selected,current,current_width,math.sign(params:get("beat_length"))
end

function bind()
  local selected,current,current_width,direction=get_selected()
  if current_width==0 then
    do return end
  end
  print(selected,current,current_width,direction)
  local deleted=false
  for sn=current,current+current_width-1 do
    local val=params:get(selected.."_"..sn)
    if val~=0 then
      deleted=true
    end
    params:set(selected.."_"..sn,0)
  end
  if deleted then
    -- make sure nothing is left behind
    local last_val=0
    for sn=1,32 do
      local val=params:get(selected.."_"..sn)
      if last_val==0 and math.abs(val)%10==1 then
        params:set(selected.."_"..sn,val+1*math.sign(val))
      end
      last_val=val
    end
    do return end
  end
  for sn=current,current+current_width-1 do
    local val=params:get("sample")*10+1
    if sn==current then
      val=val+1
    end
    params:set(selected.."_"..sn,val*direction)
  end
end

-- runs after you unload a script
function cleanup()
end

-- key function
function key(k,z)
  if k==3 and z==1 then
    bind()
  elseif k==2 then
    k2on=z==1
    elseif k==1 then 
    for i=1,10 do
      params:set("sample",math.random(1,8))
      params:set("selected",math.random(1,6))
      params:set("beat_start",math.random(1,7)*4)
      params:set("beat_length",math.random(2,8)*(math.random()>0.5 and 1 or -1))
      bind()
    end
  end

end

-- encoder function
function enc(k,d)
  if k==1 then

  elseif k==2 then
    params:delta("beat_start",d)
    if params:get("beat_start")>32 then
      if params:get("selected")<6 then
        params:set("beat_start",1)
        params:delta("selected",1)
      else
        params:set("beat_start",32)
      end
    elseif params:get("beat_start")<1 then
      if params:get("selected")>1 then
        params:set("beat_start",32)
        params:delta("selected",-1)
      else
        params:set("beat_start",1)
      end
    end
  elseif k==3 then
    params:delta("beat_length",d)
  end
end

-- cause the screen to draw stuff
function redraw()
  screen.clear()

  local selected,current,current_width=get_selected()

  for i=1,6 do
    local y=24+6*i
    for j=1,32 do
      local x=(j-1)*4
      local level=4
      screen.level(level)
      screen.rect(x,y,3,2)
      screen.fill()
    end
    if selected==i then
      local x=(current-1)*4
      local z=y+4
      screen.level(5)
      screen.line_width(1)
      screen.move(x,z)
      screen.line(x+current_width*4-1,z)
      screen.stroke()
      z=z-5
      screen.move(x,z)
      screen.line(x+current_width*4-1,z)
      screen.stroke()
    end

    -- show current
    local x=(seqs[i].ix-1)*4
    local z=y+4
    screen.level(15)
    screen.line_width(1)
    screen.move(x,z)
    screen.line(x+3,z)
    screen.stroke()
    z=z-5
    screen.move(x,z)
    screen.line(x+3,z)
    screen.stroke()
  end

  for i=1,6 do
    for _,d in ipairs(hptns[i]) do
      local y=24+6*i
      local x1=(d.start-1)*4
      local x2=(d.stop)*4
      screen.level(10)
      screen.rect(x1,y,x2-x1-1,2)
      screen.fill()
      screen.level(0)
      screen.pixel(d.direction<0 and x1 or (x2-2),y)
      screen.pixel(d.direction<0 and x1+1 or (x2-3),y)
      screen.fill()
    end
  end

  -- show the name of the sample
  screen.level(15)
  screen.move(64,5)
  screen.text_center(params:string("sample"))

  if samples~=nil then
    for i=1,127 do
      screen.aa(1)
      screen.level(15)
      screen.move(i,samples[params:get("sample")].rendered[i]*10+17)
      screen.line(i+1,samples[params:get("sample")].rendered[i+1]*10+17)
      screen.stroke()
      screen.aa(0)
    end
  end

  screen.update()
end
