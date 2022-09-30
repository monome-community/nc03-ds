-- nc03 snippets graciously reused and morphed
-- zzsnzmn
-- skeletons

-- k3 start/stop
-- encoders move things around
-- k2 randomizes things
-- high return settings on reverb recomended
-- also mess with the compressor it's fun
-- v--

lfo = require 'lfo' -- assign the library to a general variable
s = require 'sequins'

sc_fn = include 'lib/sc_helpers'
sc_prm = include 'lib/sc_params' -- param-based controls over softcut
song = {}

function init()
  -- always keep this in the init, just in case the files haven't been migrated:
  sc_fn.move_samples_into_audio()
  sc_prm.init() -- build the parameters ui entries for all 6 softcut voices
  
  params:set("clock_tempo",160)

  params:set('voice 1 sample', _path.audio..'nc03-ds/01-bd/01-bd_verb-long.flac')
  params:set('voice 2 sample', _path.audio..'nc03-ds/01-bd/01-bd_verb-long.flac')
  params:set('voice 3 sample', _path.audio..'nc03-ds/01-bd/01-bd_verb-long.flac')
  params:set('voice 4 sample', _path.audio..'nc03-ds/07-hh/07-hh_verb-long.flac')
  params:set('voice 5 sample', _path.audio..'nc03-ds/07-hh/07-hh_verb-short.flac')
  params:set('voice 6 sample', _path.audio..'nc03-ds/02-sd/02-sd_default-1.flac')
  
  play_seq = {}
  -- we'll set up a 'play_seq' for each voice and fill each with 1's (trigger) and 0's (no trigger):
  -- (note that each voice's sequins can have their own length, which makes for nice rhythmic interplay)
  play_seq[1] = s{-12,12,12,24,s{0,12,24}}
  play_seq[2] = s{12,24,12,24}
  play_seq[3] = s{4,0,4,0,7,0}
  play_seq[4] = s{0,0,0,0,0}
  play_seq[5] = s{-12,0,-12,0,0,0,-12,0}
  play_seq[6] = s{0,0,0,0,0,0,0,}
  
  hz_vals = s{1,2,1,3}
  sync_vals = s{1,2,1/2,1/6,2}
  clock.run(iter)
  
  screen_dirty = true
  
  cutoff_lfo = lfo.new()
  cutoff_lfo:set('shape', 'sine')
  cutoff_lfo:set('min', -5)
  cutoff_lfo:set('max', 5)
  cutoff_lfo:set('depth', 0.5)
  cutoff_lfo:set('mode', 'free') cutoff_lfo:set('period', 20)
  cutoff_lfo:set('action', function(scaled,raw) x = scaled; screen_dirty = true end)

  lfos = {pan = {}, post_filter_fc = {}, semitone_offset = {}}
  lfos = {pan = {}, post_filter_fc = {}, semitone_offset = {}}
  
  -- softcut.voice_count equals 6, so we can just use that variable:
  for i=1,6 do
    
    -- for each voice, we'll build a panning lfo:
    lfos.pan[i] = lfo:add{
      min = -1,
      max = 1,
      action = function(scaled,raw)
        params:set('pan_'..i,scaled)
      end
    }
    
    -- for each voice, we'll build a filter cutoff lfo:
    lfos.post_filter_fc[i] = lfo:add{
      min = 20,
      max = 12000,
      action = function(scaled,raw)
        params:set('post_filter_fc_'..i, scaled)
      end
    }
    
    -- lets quantize a semitone offset:
    lfos.semitone_offset[i] = lfo:add{
      min = -7,
      max = 12,
      action = function(scaled,raw)
        -- if util.round(scaled) < 0 then
        --   scaled = -7
        -- elseif util.round(scaled) >= 0 and util.round(scaled) < 7 then
        --   scaled = 0
        -- else
        --   scaled = 12
        -- end
        -- params:set('semitone_offset_'..i, scaled)
      end
    }
    
    -- for all the voice lfos, let's do the following:
    for k,v in pairs(lfos) do
      lfos[k][i]:set('ppqn', 16) -- reduce resolution (no need for 96ppqn here)
      lfos[k][i]:set('period', math.random(15)) -- set clock periods to random values
      lfos[k][i]:start() -- start each lfo
    end
    
    -- let's adjust some additional parameters:
    if i ~= 1 then -- keep the kick unfiltered
      params:set('post_filter_dry_'..i,0) -- no dry signal
      local filters = {'lp','hp','bp'} -- index our filter types
      -- we'll turn a random filter type up to 1 (== 100%) with each script load:
      params:set('post_filter_'..filters[math.random(3)]..'_'..i,1)
      -- let's randomly set the filter q:
      params:set('post_filter_rq_'..i,math.random(90))
    end
    
  end
  
  redraw_screen = metro.init(check_dirty,0.01,-1)
  redraw_screen:start()
  -- just a random jumble:
  -- clock.run(
  --   function()
  --     while true do
  --       clock.sync(1/2)
  --       if math.random() > 0.7 then
  --         sc_fn.play_slice(math.random(6),1)
  --       end
  --       if math.random() > 0.9 then
  --         sc_fn.play_slice(math.random(2),1)
  --       end
  --       if math.random() > 0.1 then
  --         sc_fn.play_slice(math.random(2)+2,1)
  --       end
  --     end
  --   end
  -- )
end

-- function start_song()
--   song = clock.run(
--     function()
--       while true do
--         clock.sync(1/2) -- we'll just cycle through each sequence at 1/16th notes
--         for i = 1,#play_seq do
--           local step_value = play_seq[i]()
--           if step_value == 1 then
--             sc_fn.play_slice(i,1)
--           end
--         end
--       end
--     end
--   )
-- end

function start_voice(sc_voice)
  song[sc_voice] = clock.run(
    function()
      while true do
        clock.sync(1/2) -- we'll just cycle through each sequence at 1/16th notes
        local step_value = play_seq[sc_voice]()
        if step_value >= 1 then

          print(step_value)
          
          -- sc_fn
          
          params:set('semitone_offset_'..sc_voice, step_value)
          sc_fn.play_slice(sc_voice,step_value)
        end
      end
    end
  )
end

function stop_voice(sc_voice)
  clock.cancel(song[sc_voice]) 
end

_args = table.unpack

  
x = 10 
y = -56

function check_dirty()
  if screen_dirty then
    redraw_iter()
    screen_dirty = false
  end
end
  
function iter()
  while true do
    clock.sync(sync_vals())
    hertz = hz_vals()
    cutoff_lfo:set('depth', math.random())
  end
end

redraw_idx = 0
rando_woah = 40

-- funky lil screen updater
function redraw_iter()
  redraw_idx = redraw_idx % (rando_woah+1)
  -- rando_woah = (rando_woah + math.random(7)) % 16
  local i = redraw_idx
  screen.move(_args(transpose(x, y, -i*2)))
  screen.level(i%10)
  screen.text(")))))))))))))))))))))))))))))))))))))))))))))")
  
  screen.move(_args(transpose(y, x, i)))
  screen.level(i%10)
  screen.text("///////////////////////////////////////////////////////////////////////////////////")
  
  screen.move(_args(transpose(y+10, x+20, i*3)))
  screen.level(i%16)
  screen.text("sssssssssssssssssssssssssssssssssssssssssssssssskeletonsssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssss")
  
  _x=x+20
  _y=y+20
  _y = _y+i
  screen.move(_args(transpose(x, y, i*2)))
  screen.level(i)
  screen.text(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>")
  
  screen.move(_args(transpose(10, 43, 4)))
  screen.update()
  redraw_idx = redraw_idx + 1
end

function transpose(originX, originY, distance, angle)
  return {originX+distance, originY+distance}
end

-- press K3 to start/stop:
function key(n,z)
  if n == 3 and z == 1 then
    if cutoff_lfo:get('enabled') == 1 then
      cutoff_lfo:stop()
      stop_voice(1)
      stop_voice(2)
      stop_voice(3)
      stop_voice(4)
      stop_voice(5)
      stop_voice(6)
    else
      cutoff_lfo:start()
      start_voice(1)
      start_voice(2)
      start_voice(3)
      start_voice(4)
      start_voice(5)
      start_voice(6)
    end
  end
  if n == 2 and z == 1 then
    params:read(math.random(6))
    play_seq[math.random(6)] = s{math.random(1)*5,math.random(1)*12,math.random(6)*7%12,0,math.random(100) * 7 % 12,0}
  end
end


function enc(n,d)
  -- number = number + d
  if n == 1 then
    x = x + d
  end
  if n == 2 then
    y = y + d
  end
  if n == 3 then
    rando_woah = math.random(40) + 1
    if (rando_woah % 7) >= 3 then
      doing_stuff()
    end
  end
  screen_dirty=true
end

function doing_stuff() 
    play_seq[math.random(6)] = s{math.random(1)*5,math.random(1)*12,math.random(6)*7%12,0,math.random(100) * 7 % 12,0}
end
