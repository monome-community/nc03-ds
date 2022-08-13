-- scarlet (nc03 - dressed in sequins)
-- @dndrks
--
-- E1 volume
-- E2 cadence (hold K1)
-- E3 horizon
-- K1 stability
-- K2 relax
-- K3 bind


sc_prm = include 'lib/sc_params' -- param-based controls over softcut
sc_fn = include 'lib/sc_helpers' -- helper functions for different softcut actions, used by 'sc_params'
lfo = require 'lfo' -- parameter-based lfo library

local period_screen = false
local global_period = 1
local pre_script_level = params:get('softcut_level')

s = require 'sequins'

function init()
  -- initliaze our softcut parameters:
  sc_prm.init()
  
  -- build LFOs:
  lfos = {level = {}, pan = {}, semitone_offset = {}, pitch_control = {}, post_filter_fc = {}}
  -- to restore our pre-lfo states, we'll capture the current values for each of our lfo destinations:
  pre_lfo_values = {level = {}, pan = {}, semitone_offset = {}, pitch_control = {}, post_filter_fc = {}}
  
  for i = 1,softcut.VOICE_COUNT do
    
    lfos.level[i] = lfo:add{
      -- for each lfo, we'll use the current value as the center of the movement:
      action = function(scaled,raw)
        scaled = util.linlin(0,1,0,-1,scaled)
        params:set('level_'..i,pre_lfo_values.level[i] + scaled)
      end
    }
    
    lfos.pan[i] = lfo:add{
      min = -1,
      max = 1,
      action = function(scaled,raw)
        local scaled_min = pre_lfo_values.pan[i] - lfos.pan[i].depth
        local scaled_max = pre_lfo_values.pan[i] + lfos.pan[i].depth
        raw = util.linlin(0,1,scaled_min, scaled_max, raw)
        params:set('pan_'..i,raw)
      end
    }
    
    lfos.semitone_offset[i] = lfo:add{
      min = -48,
      max = 48,
      action = function(scaled,raw)
        local centroid = 96 * (lfos.semitone_offset[i].depth/2)
        local scaled_min = pre_lfo_values.semitone_offset[i] - centroid
        local scaled_max = pre_lfo_values.semitone_offset[i] + centroid
        raw = util.linlin(0,1,scaled_min, scaled_max, raw)
        params:set('semitone_offset_'..i, raw)
      end
    }
    
    lfos.pitch_control[i] = lfo:add{
      min = -25,
      max = 25,
      action = function(scaled,raw)
        local centroid = 50 * (lfos.pitch_control[i].depth/2)
        local scaled_min = pre_lfo_values.pitch_control[i] - centroid
        local scaled_max = pre_lfo_values.pitch_control[i] + centroid
        raw = util.linlin(0,1,scaled_min, scaled_max, raw)
        params:set('pitch_control_'..i, raw)
      end
    }
    
    lfos.post_filter_fc[i] = lfo:add{
      min = 20,
      max = 12000,
      action = function(scaled,raw)
        local centroid = 11980 * (lfos.post_filter_fc[i].depth/2)
        local scaled_min = pre_lfo_values.post_filter_fc[i] - centroid
        local scaled_max = pre_lfo_values.post_filter_fc[i] + centroid
        raw = util.linlin(0,1,scaled_min, scaled_max, raw)
        params:set('post_filter_fc_'..i, raw)
      end
    }
    
    for k,v in pairs(lfos) do
      lfos[k][i]:set('ppqn', 16)
    end
    
  end

  -- build some sequins-based trigger sequencers:
  trigger_seqs = {
    {
      s{1,0,0,0,1,0,0,0,s{1,1,0,1}},
      s{0,1,0,1,1,0,1,0,0,s{0,1,1,0,1,1,0}},
      s{1,0,1,0,0,1,0,1,0,0},
      s{0,0,0,0,0,0,0,1},
      s{0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0},
      s{0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0},
    },
    {
      s{0},
      s{1,0,1,s{0,0,1,1,0,0,1}},
      s{1,0,1,0,0,0,0,0,1,1,0,0},
      s{0,1,0,s{1,1,1,0}},
      s{0,s{1,0,0,1}},
      s{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
    },
    {
      s{1,0,0,0,0,0,1,0,0,0,0,0,0,0},
      s{0,1,0,0,0,0,1,1,0,0},
      s{0,0,0,0,0,0,0,0,1,0,0,0},
      s{0,0,0,0,1,0},
      s{0,0,0,1,0,s{0,1,0,0,1,0,0,1,1,1}},
      s{0},
    },
  }
  
  selected_seq = 1
  queued_seq = 1
  
  -- pre-load audio files:
  -- kits: 'default-1', 'default-2', 'fltr-amod-eq', 'fm-lite', 'heavy', 'mods-1', 'mods-2', 'verb-long', 'verb-short'
  sc_fn.load_kit('default-1')
  -- load a longer decay kick:
  params:set("voice 1 sample",_path.audio.."nc03-ds/01-bd/01-bd_default-2.flac")
  
  screen_dirty = true
  screen_redraw = metro.init(draw_screen, 1/15, -1)
  screen_redraw:start()
  
  for i = 1,6 do
    params:set("post_filter_dry_"..i, 0)
    params:set("post_filter_lp_"..i, 1)
    params:set("post_filter_rq_"..i, math.random(50,80))
  end
  
end

function randomize_lfos()
  for k,v in pairs(lfos) do
    for i = 1,6 do
      pre_lfo_values[k][i] = params:get(k.."_"..i)
      lfos[k][i]:set('depth', math.random(100)/100)
      local shapes = {'sine','saw','square'}
      lfos[k][i]:set('shape', shapes[math.random(#shapes)])
      lfos[k][i]:set('period', global_period)
      lfos[k][i]:start()
    end
  end
end

function zero_lfos()
  for k,v in pairs(lfos) do
    for i = 1,6 do
      lfos[k][i]:stop()
      params:set(k.."_"..i,pre_lfo_values[k][i])
    end
  end
end

function enc(n,d)
  if n == 1 then
    params:delta('softcut_level', d)
  elseif n == 2 then
    if randomizing then
      if not period_screen then
        period_screen = true
      else
        global_period = util.clamp(global_period + d,1,10)
        for k,v in pairs(lfos) do
          for i = 1,6 do
            lfos[k][i]:set('period', global_period)
          end
        end
      end
    end
  elseif n == 3 then
    queued_seq = util.clamp(queued_seq+d, 1, #trigger_seqs)
  end
  screen_dirty = true
end

function key(n,z)
  if n == 3 and z == 1 then
    play(queued_seq)
  elseif n == 2 and z == 1 then
    stop()
  elseif n == 1 then
    if z == 1 then
      randomize_lfos()
      randomizing = true
    else
      period_screen = false
      zero_lfos()
      randomizing = false
    end
  end
  screen_dirty = true
end

function play(seq)
  stop()
  reset_indices()
  seq_clock = clock.run(
    function()
      while true do
        local _c = trigger_seqs[seq]
        clock.sync(1/4)
        for i = 1,#_c do
          local val = _c[i]()
          if val == 1 then
            sc_fn.play_slice(i,1)
          end
        end
        screen_dirty = true
      end
    end
  )
  selected_seq = queued_seq
  seq_active = true
end

function stop()
  if seq_clock then
    clock.cancel(seq_clock)
    seq_active = false
  end
end

function reset_indices()
  for i = 1,#trigger_seqs[selected_seq] do
    trigger_seqs[selected_seq][i]:reset()
  end
  screen_dirty = true
end

function draw_screen()
  if screen_dirty then
    redraw()
    screen_dirty = false
  end
end

function redraw()
  screen.clear()
  screen.level(5)
  screen.move(128,10)
  screen.text_right("queued seq: "..queued_seq)
  if not period_screen then
    for i = 1,#trigger_seqs[selected_seq] do
      local current_ix = trigger_seqs[selected_seq][i].ix
      local current_val = trigger_seqs[selected_seq][i].data[current_ix]
      if type(current_val) ~= "table" then
        screen.level(current_val == 1 and 15 or 3)
        screen.move((18*(i-1))+15,30)
        screen.text_center(i)
        screen.move((18*(i-1))+15,40)
        screen.text_center(current_val)
      end
    end
  else
    screen.move(64,32)
    screen.level(15)
    screen.text_center('lfo period: '..global_period..' beats')
  end
  screen.level(5)
  screen.move(0,60)
  screen.text(seq_active and "K2: stop" or "")
  screen.move(128,60)
  screen.text_right("K3: load seq "..queued_seq)
  screen.move(0,12)
  screen.text(randomizing and "~~~" or "")
  screen.update()
end

function cleanup()
  params:set('softcut_level', pre_script_level)
end
