-- gimbal         ......
-- nc03 - dressed ... in sequins
-- @dewb      ...........
--          ...........      [ ]
--   ^        ..........   
-- E1 volume  ........  K1 stability
-- E2 cadence  .....  K2 relax
-- E3 horizon  ......  K3 bind
-- 


s = require 'sequins'
lfo = require 'lfo' 
musicutil = require 'musicutil'
util = require 'util'
tabutil = require 'lib/tabutil'
sc_params = include 'lib/sc_params' 
sc_helpers = include 'lib/sc_helpers' 

local pre_script_level = params:get('softcut_level')

local territory = {
  {1, 6, 4, 5},
  {3, 7, 5, 1},
  {5, 4, 3, 7},
  {4, 3, 6, 1}
}

sequences = {
  s{1,0,0,1,0},
  s{1,0,1,s{0,0,1,1,0,0,1}},
  s{1,0,1,0,0,0,0,0,1,1,0,0},
  s{0,1,0,s{1,1,1,0}},
  s{0,s{1,0,0,1}},
  s{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
  s{s{0, 1, 1}, 0, s{1, 1, 0}, 0}
}

strum_sequence_a = s{0.036, 0.016, 0.036, 0.025, 0.025, 0.036, s{0, 0, 0, 0.025, 0.016}}
strum_sequence_b = s{0.025, 0.016, 0, 0.016, 0.016, 0.025, 0, s{0, 0, 0.016, 0.036}}

step_length_sequence = {
  s{1/4, 1/4, 1/4, s{1/4, 1/4, 1/4, s{1/8, 1/8}:all(), 1/4, 1/4, 1/4, s{1/16, 3/16}:all()}},
  s{1/8, 1/8, 1/4},
}

step_length_sequence_index = 1
play_level = 0

local scale_names = {}
local current_chord_name = ""

local hits = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }

coords = {{x = 1, y = 1}, {x = 3, y = 3}, {x = 2, y = 3}, {x = 4, y = 3}, {x = 1, y = 3}}

-- pitch of 06-cb_default-1.flac is roughly D#5
base_note = 87

function update_pitches()
  local degree = territory[coords[5].y][coords[5].x]
  
  local chord = musicutil.generate_chord_scale_degree(params:get("root_note"), params:get("scale_mode"), degree, false)
  current_chord_name = musicutil.SCALE_CHORD_DEGREES[params:get("scale_mode")]['chords'][degree]

  for i = 1,3 do
    local index = i
    if math.random(3) > 2 then
      index = 3 - i + 1
    end
    if math.random(10) > 9 then
      chord[index] = chord[index] - 12
    end
    params:set('semitone_offset_'..3+i, chord[index] - base_note)
  end
end

function init()
  for i = 1, #musicutil.SCALE_CHORD_DEGREES do
    table.insert(scale_names, string.lower(musicutil.SCALE_CHORD_DEGREES[i].name))
  end
  
  sc_params.init()
  
  params:add{type = "option", id = "scale_mode", name = "scale mode",
    options = scale_names, default = 2,
  }
  params:add{type = "number", id = "root_note", name = "root note",
    min = 0, max = 127, default = 57, formatter = function(param) return musicutil.note_num_to_name(param:get(), true) end,
  }
  
  params:add{type = "option", id = "show_lfos", name = "show lfos", options = {"yes", "no"}, default = 1 }
  params:add{type = "option", id = "show_info", name = "show text info", options = {"yes", "no"}, default = 1 }
  
  lfos = {x = {}, y = {}, pan = {}, post_filter_fc = {}}
 
  for i = 1,5 do
    lfos.x[i] = lfo:add{
      ppqn = 16,
      action = function(scaled,raw)
        coords[i].x = math.ceil(raw*4)
      end
    }
    lfos.y[i] = lfo:add{
      ppqn = 16,
      action = function(scaled,raw)
        coords[i].y = math.ceil(raw*4)
      end
    }
    
    lfos.pan[i] = lfo:add{
      min = -1,
      max = 1,
      action = function(scaled,raw)
        local scaled_min = 0 - lfos.pan[i].depth
        local scaled_max = 0 + lfos.pan[i].depth
        raw = util.linlin(0,1,scaled_min, scaled_max, raw)
        params:set('pan_'..i,raw)
      end
    }
  end
  
  for i = 1,3 do
    lfos.post_filter_fc[i] = lfo:add{
      min = 20,
      max = 12000,
      ppqn = 16,
      action = function(scaled,raw)
        local centroid = 11980 * (lfos.post_filter_fc[i].depth/2)
        local scaled_min = 8000 - centroid
        local scaled_max = 8000 + centroid
        raw = util.linlin(0,1,scaled_min, scaled_max, raw)
        params:set('post_filter_fc_'..i, raw)
        if (i == 4) then
          params:set('post_filter_fc_'..i+1, raw)
          params:set('post_filter_fc_'..i+2, raw)
        end
      end
    }
  end

  params:set("voice 1 sample",_path.audio.."nc03-ds/01-bd/01-bd_default-1.flac")
  params:set("voice 2 sample",_path.audio.."nc03-ds/04-cp/04-cp_default-2.flac")
  params:set("voice 3 sample",_path.audio.."nc03-ds/07-hh/07-hh_default-1.flac")
  params:set("voice 4 sample",_path.audio.."nc03-ds/06-cb/06-cb_default-1.flac")
  params:set("voice 5 sample",_path.audio.."nc03-ds/06-cb/06-cb_default-1.flac")
  params:set("voice 6 sample",_path.audio.."nc03-ds/06-cb/06-cb_default-1.flac")

  randomize_lfos()

  screen_dirty = true
  screen_redraw = metro.init(draw_screen, 1/15, -1)
  screen_redraw:start()
  
end

function get_pin_location(n)
  local c = coords[n]
  return territory[c.y][c.x]
end

function randomize_lfos()
  for k,v in pairs(lfos) do
    for i = 1,#lfos[k] do
      lfos[k][i]:set('depth', math.random(100)/100)
      local shapes = {'sine','saw'}
      lfos[k][i]:set('shape', shapes[math.random(#shapes)])
      lfos[k][i]:set('period', math.random(i == 5 and 24 or 64))
      lfos[k][i]:start()
    end
  end
end

function adjust_lfo_period_preserving_phase(l, new_period)
  local new_phase_counter = l.phase_counter + (1/l.ppqn)
  local new_phase
  if l.mode == "clocked" then
    new_phase = new_phase_counter / l.period
  else
    new_phase = new_phase_counter * clock.get_beat_sec() / l.period
  end
  
  local adjusted_phase_counter = (new_phase * new_period / clock.get_beat_sec()) - 1/l.ppqn
  
  l:set('mode', 'free')
  l:set('period', new_period)
  l.phase_counter = adjusted_phase_counter
end

function enc(n,d)
  if n == 1 then
    params:delta('softcut_level', d)
  elseif n == 2 then
    -- todo:  adjust step_length_sequence_index
  elseif n == 3 then
    for k,v in pairs(lfos) do
      for i = 1,#lfos[k] do
        local l = lfos[k][i]
        adjust_lfo_period_preserving_phase(l, math.max(l:get('period') * (1 - d/40), 0.02))
        --lfos[k][i]:set('mode', 'free')
        --lfos[k][i]:set('period', math.max(lfos[k][i]:get('period') - d, 0.02))
      end
    end
  end
  screen_dirty = true
end

function update_sounds()
  if play_level <= 2 then
    params:set("voice 4 sample",_path.audio.."nc03-ds/06-cb/06-cb_default-1.flac")
    params:set("voice 5 sample",_path.audio.."nc03-ds/06-cb/06-cb_default-1.flac")
    params:set("voice 6 sample",_path.audio.."nc03-ds/06-cb/06-cb_default-1.flac")
    params:set("reverse_1", 0)
    params:set("reverse_2", 0)
    params:set("reverse_3", 0)
    params:set("reverse_4", 0)
    params:set("reverse_5", 0)
    params:set("reverse_6", 0)
  elseif play_level == 3 then
    params:set("voice 4 sample",_path.audio.."nc03-ds/06-cb/06-cb_default-1.flac")
    if math.random(3) > 2 then
      params:set("voice 5 sample",_path.audio.."nc03-ds/06-cb/06-cb_fm-lite.flac")
    end
    params:set("voice 6 sample",_path.audio.."nc03-ds/06-cb/06-cb_default-2.flac")
    params:set("reverse_1", 0)
    params:set("reverse_2", math.random(10) > 6 and 1 or 0)
    params:set("reverse_3", 0)
    params:set("reverse_4", 0)
    params:set("reverse_5", math.random(10) > 5 and 1 or 0)
    params:set("reverse_6", math.random(10) > 7 and 1 or 0)
  end
end

function key(n,z)
  if n == 3 and z == 1 then
    play_level = math.min(play_level + 1, 3)
    if play_level > 0 and not seq_active then play() end
    sounds_dirty = true
  elseif n == 2 and z == 1 then
    play_level = math.max(play_level - 1, 0)
    if play_level == 0 and seq_active then stop() end
    sounds_dirty = true
    if play_level < 2 then current_chord_name = "" end
  elseif n == 1 then
    if z == 1 then
      randomize_lfos()
      randomizing = true
    else
      randomizing = false
    end
  end
  screen_dirty = true
end

function clear_hits()
  for i = 1,16 do
    hits[i] = 0
  end
end

function register_hit(c)
  local addr = c.x + (c.y - 1)*4
  hits[addr] = hits[addr] + 1
  screen_dirty = true
end

function play()
  stop()
  reset_indices()
  seq_clock = clock.run(
    function()
      while true do
        
        clock.sync(step_length_sequence[step_length_sequence_index]())
        
        if sounds_dirty then
          update_sounds()
          sounds_dirty = false
        end
        
        clear_hits()
        screen_dirty = true
        
        for i = 1,4 do
          local seq_num = get_pin_location(i)
          local val = sequences[seq_num]()
          
          if val == 1 then
            register_hit(coords[i])
          
            if i == 4 then
              if play_level >= 2 then
                update_pitches()
  
                sc_helpers.play_slice(4,4)
              
                clock.sleep(strum_sequence_a())
                sc_helpers.play_slice(5,5)
              
                if math.random(10) > 3 then
                  clock.sleep(strum_sequence_b())
                  sc_helpers.play_slice(6,6)
                end
              end

            else
              sc_helpers.play_slice(i,1)
            end
          end
        end
        
        clock.sleep(0.08)
        clear_hits()
        screen_dirty = true
        
        
        
      end
    end
  )
  seq_active = true
end

function stop()
  if seq_clock then
    clock.cancel(seq_clock)
    seq_active = false
  end
  clear_hits()
  screen_dirty = true
end

function reset_indices()
  for i = 1,#sequences do
    sequences[i]:reset()
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
  
  --for n = 1, 5 do
  --screen.move(128,n*10)
  --screen.text_right(coords[n].x.. " "..coords[n].y)
  --end
  
  if params:get("show_info") == 1 then
    local carets = ""
    for i = 1, play_level do
      carets = carets..">"
    end
    screen.move(128,60)
    screen.text_right(carets)
    if play_level >= 2 then
      screen.move(0,60)
      screen.text(current_chord_name)
    end
  end
  
  for j = 1, 4 do
    for i = 1, 4 do
      local hitcount = hits[i + (j - 1) * 4]
      screen.rect(42 + (i - 1) * 12, 10 + (j - 1) * 12, 10, 10)
      if hitcount > 0 then
        screen.level(math.min(4 * hitcount, 15))
        screen.stroke()
        screen.rect(42 + (i - 1) * 12, 10 + (j - 1) * 12, 10, 10)
        screen.fill()
      else
        screen.level(1)
        screen.stroke()
      end
    end
  end
  
  if params:get("show_lfos") == 1 then
    for n = 1, 5 do
      if (n == 4 or n == 5) and play_level < 2 then
        break
      end
      local x = lfos.x[n].raw
      local y = lfos.y[n].raw
      screen.rect(42 + x * 46 - 1, 10 + y * 46 - 1, 3, 3)
      screen.level(n == 5 and 2 or 0)
      screen.fill()
      screen.pixel(42 + x * 46, 10 + y * 46)
      screen.level(n == 5 and 0 or 3 + n * 2)
      screen.fill()
    end
  end
  
  screen.update()
end

function cleanup()
  params:set('softcut_level', pre_script_level)
end
