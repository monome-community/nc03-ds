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

territory = {
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
  s{0,0,0,0,0,0,0,1},
  s{s{0, 1, 1}, 0, s{1, 1, 0}, 0}
}

strum_sequence_a = s{0.036, 0.016, 0.036, 0.025, 0.025, 0.036, s{0, 0, 0, 0.025, 0.016}}
strum_sequence_b = s{0.025, 0.016, 0, 0.016, 0.016, 0.025, 0, s{0, 0, 0.016, 0.036}}

step_length_sequences = {
  {
    s{1/2},
    s{1/4},
    s{1/4},
    s{1/4, 1/4, 1/4, 1/8, 1/8},
    s{1/4, 1/4, 1/4, 1/8, 1/8},
    s{1/8},
    s{1/8},
    s{1/8, 1/8, 1/8, 1/8, 1/8, 1/8, 1/8, 1/16, 1/16},
  },
  {
    s{1, 1, 1, 1/2, 1/2},
    s{1, 1/2, 1/2, 1, 1/4, 1/4, 1/4, 1/4},
    s{1/2, 1/4, s{1/2, 1/4, s{1/8, 1/8}:all(), 1/2, 1/4, s{1/16, 3/16}:all()}},
    s{1/4, 1/4, 1/4, s{1/4, 1/4, 1/4, s{1/8, 1/8}:all(), 1/4, 1/4, 1/4, s{1/16, 3/16}:all()}},
    s{1/4, 1/4, 1/4, s{1/4, 1/4, 1/4, s{1/8, 1/8}:all(), 1/4, 1/4, 1/4, s{1/16, 3/16}:all()}},
    s{1/4, 1/4, 1/4, s{1/4, 1/4, 1/4, s{1/8, 1/8}:all(), 1/4, 1/4, 1/4, s{1/16, 3/16}:all()}},
    s{1/2, 1/8, 1/8, s{1/4, s{1/8, 1/8}:all(), 1/4, s{1/8, 1/8}:all(), 1/4, s{1/8, 1/8}:all(), 1/4, s{1/16, 3/16}:all()}},
    s{1/2, 1/8, 1/8, s{1/4, s{1/8, 1/8}:all(), 1/4, s{1/8, 1/8}:all(), 1/4, s{1/8, 1/8}:all(), 1/4, s{1/16, 3/16}:all()}},
    s{1/16},
  }
}

play_level = 0
cadence_changed = false
cadence_metro = metro.init(function() cadence_changed = false end, 3, 1)

local scale_names = {}
local current_chord_name = ""

local hits = {
  {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
  {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }
}

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
  
  params:add{type = "option", id = "scale_mode", name = "scale mode",
    options = scale_names, default = 2,
  }
  params:add{type = "number", id = "root_note", name = "root note",
    min = 0, max = 127, default = 57, formatter = function(param) return musicutil.note_num_to_name(param:get(), true) end,
  }
  
  params:add{type = "number", id = "cadence", name = "cadence", min = 1, max = 8, default = 3}
  
  params:add{type = "option", id = "show_lfos", name = "show lfos", options = {"yes", "no"}, default = 1 }
  params:add{type = "option", id = "show_info", name = "show text info", options = {"yes", "no"}, default = 1 }
  params:add{type = "option", id = "show_territory", name = "show territory", options = {"yes", "no"}, default = 2 }
  
  sc_params.init()
  
  default_alt_prob = {0,0,0,0,30,100}
  default_reverse_prob = {0,40,0,0,50,30}

  for i = 1,6 do
    params:add{type = "number", id = "voice "..i.." alt prob", name = "alt file probability ["..i.."]", default = default_alt_prob[i], 
      min = 0, max = 100, formatter = function(param) return(param:get().."%") end }
    params:add{type = "number", id = "voice "..i.." reverse prob", name = "reverse probability ["..i.."]", default = default_reverse_prob[i],
      min = 0, max = 100, formatter = function(param) return(param:get().."%") end }
    params:add_file("voice "..i.." alt sample", "alt sample", _path.audio)

    params:set_action("voice "..i.." sample",
      function(file)
        if file ~= _path.audio and play_level < 3 then
          sc_helpers.file_callback(file,i)
        elseif file == _path.audio then
        end
      end
    )
    params:set_action("voice "..i.." alt sample",
      function(file)
        if file ~= _path.audio and play_level >= 3 then
          sc_helpers.file_callback(file,i)
        elseif file == _path.audio then
        end
      end
    )

    insert_param_into_group("voice "..i.." alt sample", "voice_"..i, 4)
    insert_param_into_group("voice "..i.." alt prob", "voice_"..i, 6)
    insert_param_into_group("voice "..i.." reverse prob", "voice_"..i, 7)
  end
  
  params:add_separator("TERRITORY")

  for j = 1,4 do
    for i = 1,4 do
      params:add{type = "number", id = "territory "..i..","..j, name = "territory "..i..","..j, default = territory[j][i], 
        action = function(val)
          territory[j][i] = val
        end
      }
    end
  end

  params:set("voice 1 sample",_path.audio.."nc03-ds/01-bd/01-bd_default-1.flac")
  params:set("voice 2 sample",_path.audio.."nc03-ds/04-cp/04-cp_default-2.flac")
  params:set("voice 3 sample",_path.audio.."nc03-ds/07-hh/07-hh_default-1.flac")
  params:set("voice 4 sample",_path.audio.."nc03-ds/06-cb/06-cb_default-1.flac")
  params:set("voice 5 sample",_path.audio.."nc03-ds/06-cb/06-cb_default-1.flac")
  params:set("voice 6 sample",_path.audio.."nc03-ds/06-cb/06-cb_default-1.flac")

  params:set("voice 1 alt sample",_path.audio.."nc03-ds/01-bd/01-bd_default-2.flac")
  params:set("voice 2 alt sample",_path.audio.."nc03-ds/04-cp/04-cp_default-1.flac")
  params:set("voice 3 alt sample",_path.audio.."nc03-ds/07-hh/07-hh_default-2.flac")
  params:set("voice 4 alt sample",_path.audio.."nc03-ds/06-cb/06-cb_default-2.flac")
  params:set("voice 5 alt sample",_path.audio.."nc03-ds/06-cb/06-cb_fm-lite.flac")
  params:set("voice 6 alt sample",_path.audio.."nc03-ds/06-cb/06-cb_default-2.flac")

  init_lfos()
  randomize_lfos()

  screen_dirty = true
  screen_redraw = metro.init(draw_screen, 1/15, -1)
  screen_redraw:start()
  
end

function init_lfos()
  
  lfos = {x = {}, y = {}, pan = {}, post_filter_fc = {}}
 
  for i = 1,5 do
    lfos.x[i] = lfo:add{
      ppqn = 16,
      action = function(scaled,raw)
        coords[i].x = math.ceil(raw*4)
        screen_dirty = true
      end
    }
    lfos.y[i] = lfo:add{
      ppqn = 16,
      action = function(scaled,raw)
        coords[i].y = math.ceil(raw*4)
        screen_dirty = true
      end
    }
    
    lfos.pan[i] = lfo:add{
      min = -1,
      max = 1,
      action = function(scaled,raw)
        local scaled_min = 0 - lfos.pan[i].depth
        local scaled_max = 0 + lfos.pan[i].depth
        raw = util.linlin(0,1,scaled_min, scaled_max, raw)
        params:set("pan_"..i,raw)
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
        params:set("post_filter_fc_"..i, raw)
        if (i == 4) then
          params:set("post_filter_fc_"..i+1, raw)
          params:set("post_filter_fc_"..i+2, raw)
        end
      end
    }
  end
end

function get_pin_location(n)
  local c = coords[n]
  return territory[c.y][c.x]
end

function randomize_lfos()
  for k,v in pairs(lfos) do
    for i = 1,#lfos[k] do
      lfos[k][i]:set("depth", math.random(100)/100)
      local shapes = {"sine","saw"}
      lfos[k][i]:set("shape", shapes[math.random(#shapes)])
      lfos[k][i]:set("period", math.random(i == 5 and 24 or 64))
      lfos[k][i]:start()
    end
  end
end

function enc(n,d)
  if n == 1 then
    params:delta("softcut_level", d)
  elseif n == 2 then
    params:delta("cadence", d)
    cadence_changed = true
    cadence_metro:start(3, 1)
  elseif n == 3 then
    for k,v in pairs(lfos) do
      for i = 1,#lfos[k] do
        local l = lfos[k][i]
        adjust_lfo_period_preserving_phase(l, math.max(l:get('period') * (1 - d/40), 0.02))
      end
    end
  end
  screen_dirty = true
end

function update_sounds()
  if play_level <= 2 then
    for i = 1,6 do
      sc_helpers.file_callback(params:get("voice "..i.." sample"), i)
      params:set("reverse_"..i, 0)
    end
  elseif play_level == 3 then
    for i = 1,6 do
      if math.random(100) < params:get("voice "..i.." alt prob") then
        sc_helpers.file_callback(params:get("voice "..i.." alt sample"), i)
      end
      if math.random(100) < params:get("voice "..i.." reverse prob") then
        params:set("reverse_"..i, 1)
      end
    end
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

function clear_hits(bank)
  for i = 1,16 do
    hits[bank][i] = 0
  end
end

function register_hit(bank, c)
  local addr = c.x + (c.y - 1)*4
  hits[bank][addr] = hits[bank][addr] + 1
  screen_dirty = true
end

function play()
  stop()
  reset_indices()
  
  drum_seq_clock = clock.run(
    function()
      while true do
        clock.sync(step_length_sequences[1][params:get("cadence")]())
        
        if sounds_dirty then
          update_sounds()
          sounds_dirty = false
        end
        
        clear_hits(1)
        screen_dirty = true
        
        for i = 1,3 do
          local seq_num = get_pin_location(i)
          local val = sequences[seq_num]()
          
          if val == 1 then
            register_hit(1, coords[i])
            sc_helpers.play_slice(i,1)
          end
        end
        
        clock.sleep(0.08)
        clear_hits(1)
        screen_dirty = true
      end
    end
  )
  
  chord_seq_clock = clock.run(
    function()
      while true do
        clock.sync(step_length_sequences[2][params:get("cadence")]())
        
        if sounds_dirty then
          update_sounds()
          sounds_dirty = false
        end
        
        clear_hits(2)
        screen_dirty = true
        
        local pin_index = 4
        local seq_num = get_pin_location(pin_index)
        local val = sequences[seq_num]()
          
        if play_level >= 2 and val == 1 then
          register_hit(2, coords[pin_index])
          update_pitches()
  
          sc_helpers.play_slice(4,4)
              
          clock.sleep(strum_sequence_a())
          sc_helpers.play_slice(5,5)
              
          if math.random(10) > 3 then
            clock.sleep(strum_sequence_b())
            sc_helpers.play_slice(6,6)
          end
        end
        
        clock.sleep(0.08)
        clear_hits(2)
        screen_dirty = true
      end
    end
  )
  seq_active = true
end

function stop()
  if drum_seq_clock then
    clock.cancel(drum_seq_clock)
  end
  if chord_seq_clock then
    clock.cancel(chord_seq_clock)
  end
  seq_active = false
  clear_hits(1)
  clear_hits(2)
  screen_dirty = true
end

function reset_indices()
  for i = 1,#sequences do
    sequences[i]:reset()
  end
  for i = 1,#strum_sequence_a do
    strum_sequence_a[i]:reset()
  end
  for i = 1,#strum_sequence_b do
    strum_sequence_b[i]:reset()
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
    screen.move(128,10)
    if cadence_changed then
      screen.text_right("c "..params:get("cadence"))
    end
  end
  
  for j = 1, 4 do
    for i = 1, 4 do
      local hit_index = i + (j - 1) * 4
      local hitcount = hits[1][hit_index] + hits[2][hit_index]
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
  
  if params:get("show_territory") == 1 then
    screen.level(1)
    for j = 1, 4 do
      for i = 1, 4 do
        local t = territory[j][i]
        local offset = screen.text_extents(tostring(t))/2
        if offset == 2 then offset = 3 end
        screen.move(46 + (i - 1) * 12 + offset, 17 + (j - 1) * 12)
        screen.text_right(t)
      end
    end
  end
  
  if params:get("show_lfos") == 1 then
    for n = 1, 5 do
      if (n == 4 or n == 5) and play_level < 2 then
        break
      end
      local x = 42 + lfos.x[n].raw * 46 - 1
      local y = 10 + lfos.y[n].raw * 46 - 1
      screen.rect(x - 1, y - 1, 3, 3)
      screen.level(n == 5 and 2 or 0)
      screen.fill()
      if n ~= 4 then
        screen.pixel(x, y)
        screen.level(n == 5 and 0 or 3 + n * 2)
        screen.fill()
      else
        screen.pixel(x - 1, y)
        screen.pixel(x + 1, y)
        screen.pixel(x, y - 1)
        screen.pixel(x, y + 1)
        screen.level(3)
        screen.fill()
      end
    end
  end
  
  screen.update()
end

function cleanup()
  params:set('softcut_level', pre_script_level)
end

--- utility functions not core to script behavior below

-- change the period of an lfo object without discontinuities in phase
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

-- move a parameter not in a group inside the group
function insert_param_into_group(param_id, group_id, insert_position)
  local group_index = params.lookup[group_id]
  local group = params.params[group_index]
  local original_index = params.lookup[param_id]
  local new_index = group_index + insert_position

  -- move the param
  local p = table.remove(params.params, original_index)
  table.insert(params.params, new_index, p)

  -- increase the group size
  group.n = group.n + 1

  -- fix up the indices in params.lookup
  for k, v in pairs(params.lookup) do
    if v >= new_index and v < original_index then
      params.lookup[k] = v + 1
    end
  end

  -- fix up the params.hidden table
  table.insert(params.hidden, new_index, table.remove(params.hidden, original_index))

  params.lookup[param_id] = new_index

end
