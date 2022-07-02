-- scarlet (nc03 - dressed in sequins)
-- @dndrks
--
-- E1 volume
-- E2 stability
-- E3 horizon
-- K2 relax
-- K3 bind


sc_prm = include 'lib/sc_params' -- param-based controls over softcut
sc_fn = include 'lib/sc_helpers' -- helper functions for different softcut actions, used by 'sc_params'
lfos = include 'lib/lfos' -- parameter-based lfo library

s = require 'sequins'

function init()
  -- initliaze our softcut parameters:
  sc_prm.init()
  
  for i = 1,softcut.VOICE_COUNT do
    -- we'll register script parameters (by ID) to LFO groups and assign callbacks for the LFO output values.
    --    eg. lfos:register('param_id', 'desired group', function(x) parse_value(x) end)
    --    callbacks have two string-based templates:
    --      a. 'map param' will change the param's value (via params:set(param_id)), which will also execute the action.
    --      b. 'param action' will execute the script param's action *without* changing the param's value
    --    callbacks can also be freely assigned, eg. function(val) params:lookup_param('filter cutoff').action(val) end
    lfos:register('level_'..i, 'LEVELS', 'param action')
    lfos:register('pan_'..i, 'PAN', 'param action')
    lfos:register('semitone_offset_'..i, 'SEMITONE OFFSET', 'param action')
    lfos:register('pitch_control_'..i, 'PITCH CONTROL', 'param action')
    lfos:register('post_filter_fc_'..i, 'FILTER CUTOFF', 'param action')
  end
  
  -- alternatively, register param LFOs to voice-based groups:
  -- for i = 1,softcut.VOICE_COUNT do
  --   lfos:register('level_'..i, 'voice '..i, 'param action')
  --   lfos:register('pan_'..i, 'voice '..i, 'param action')
  --   lfos:register('semitone_offset_'..i, 'voice '..i, 'param action')
  --   lfos:register('pitch_control_'..i, 'voice '..i, 'param action')
  --   lfos:register('post_filter_fc_'..i, 'voice '..i, 'param action')
  -- end
  
  -- finally, add our new LFO parameters:
  lfos:add_params()
  
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
  
  screen_dirty = true
  screen_redraw = metro.init(draw_screen, 1/15, -1)
  screen_redraw:start()
  
  for i = 1,6 do
    params:set("post_filter_dry_"..i, 0)
    params:set("post_filter_lp_"..i, 1)
    params:set("post_filter_rq_"..i, math.random(50,80))  
    params:set("lfo max LEVELS "..i,1)
  end
  
  seq_every = 1
  
end

function randomize_lfos()
  for k,v in pairs (lfos.groups) do
    for i = 1,6 do
      params:set("lfo "..k.." "..i, 2)
      params:set("lfo depth "..k.." "..i, math.random(40,100))
      params:set("lfo position "..k.." "..i, 4)
      params:set("lfo beats "..k.." "..i, math.random(1,4))
      params:set("lfo shape "..k.." "..i, math.random(3))
    end
  end
end

function zero_lfos()
  for k,v in pairs (lfos.groups) do
    for i = 1,6 do
      params:set("lfo "..k.." "..i, 1)
    end
  end
end

function enc(n,d)
  if n == 1 then
    for i = 1,6 do
      params:delta("level_"..i,d)
    end
  elseif n == 2 then
    if d > 0 then
      if not already_randomized then
        randomize_lfos()
        params:set("voice 1 sample",_path.audio.."nc03-ds/01-bd/01-bd_default-2.flac")
        already_randomized = true
      end
    else
      if already_randomized then
        zero_lfos()
        params:set("voice 1 sample",_path.audio.."nc03-ds/01-bd/01-bd_default-1.flac")
        already_randomized = false
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
  screen.level(5)
  screen.move(0,60)
  screen.text(seq_active and "K2: stop" or "")
  screen.move(128,60)
  screen.text_right("K3: load seq "..queued_seq)
  screen.move(0,12)
  screen.text(already_randomized and "~~~" or "")
  screen.update()
end