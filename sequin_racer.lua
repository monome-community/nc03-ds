-- sequin racer
-- @tomw
-- k3 start/stop
-- k2 toggle relax
-- k1 toggle stability
-- enc3 horizon / drone
-- enc2 cadence
-- enc1 volume


sc_fn = include 'lib/sc_helpers'
sc_prm = include 'lib/sc_params' -- param-based controls over softcut
s = require 'sequins' -- https://monome.org/docs/norns/reference/lib/sequins
lfo = require 'lfo' -- parameter-based lfo library

stable = true
relax = 0
volume = 8
cadence = 4
cadence_max = 10
horizon = 0

function init()
  math.randomseed(os.time())
  
  -- always keep this in the init, just in case the files haven't been migrated:
  sc_fn.move_samples_into_audio()
  sc_prm.init() -- build the PARAMETERS UI entries for all 6 softcut voices
  
  params:set('voice 1 sample', _path.audio..'nc03-ds/01-bd/01-bd_default-1.flac')
  params:set('voice 2 sample', _path.audio..'nc03-ds/04-cp/04-cp_default-1.flac')
  params:set('voice 3 sample', _path.audio..'nc03-ds/01-bd/01-bd_verb-long.flac')
  params:set('voice 4 sample', _path.audio..'nc03-ds/05-rs/05-rs_verb-short.flac')
  params:set('voice 5 sample', _path.audio..'nc03-ds/07-hh/07-hh_verb-long.flac')
  params:set('voice 6 sample', _path.audio..'nc03-ds/07-hh/07-hh_verb-long.flac')
  
  params:set('semitone_offset_5', -42)
  params:set('level_5', 0)
  params:set('semitone_offset_6', -32)
  params:set('level_6', 0)
  for i=5,6 do
    sc_fn.play_slice(i, 1)
    softcut.loop_end(i, samples[i].start_point + 1)
    softcut.fade_time(i, 0.5)
    softcut.loop(i, 1)
  end

  cadence_change()
  
  -- track settings
  for i = 1,#play_seq do
    params:set('level_'..i, play_seq[i].vol)
    play_seq[i].cur_pattern = 1
    play_seq[i].next_pattern = 0
  end

  -- lfos
  lfos = {}
  lfos[1] = lfo:add{
    min = 1,
    max = 10,
    action = function(scaled, raw)
      cadence = scaled
      cadence_change()
    end
  }
  lfos[1]:set('ppqn', 16)
  lfos[1]:set('period', 256)

  lfos[2] = lfo:add{
    min = -0.8,
    max = 0.8,
    action = function(scaled, raw)
      params:set('pan_'..4, scaled)
    end
  }
  lfos[2]:set('ppqn', 16)
  lfos[2]:set('period', 8)
  
  for i=5,6 do
    lfos[i-2] = lfo:add{
      min = -4,
      max = 4,
      action = function(scaled, raw)
        params:set('pitch_control_'..i, scaled)
      end
    }
    lfos[i-2]:set('ppqn', 16)
    lfos[i-2]:set('period', 128)
  end
  
  for i=2,#lfos do
    lfos[i]:start()
  end
  
  draw_init()
end

function enc(n, d)
  if n == 1 then
    volume = util.clamp(volume + d, 0, 10)
    audio.level_cut(volume / 10)
  elseif n == 2 then
    cadence = util.clamp(cadence + d, 1, cadence_max)
    cadence_change()
    lfos[1]:stop()
  elseif n == 3 then
    horizon = util.clamp(horizon + d, 0, 10)
    horizon_change()
  end
  screen_dirty = true
end

function key(n,z)
  if z == 1 then
    if n == 1 then
      stable = not stable
    elseif n == 2 then
      if relax > 0 then
        -- change to not relaxed
        delay_off()
        relax = 0
        stable = true
        lfos[1]:start()
      else
        -- change to relaxed
        delay_on()
        relax = 1
        stable = false
        lfos[1]:stop()
      end
      
      for i = 2, 3 do
        params:set('level_'..i, relax == 0 and play_seq[i].vol or 0)
      end
      
    elseif n == 3 then
      if song == nil then
        start_song()
      else
        stop_song()
      end
    end
    screen_dirty = true
  end
end

play_seq = {
  -- track 1 - kick
  {
    vol = 0.75,
    pitch = false,
    patterns = {
      { s{1, 0, 0, 0} },
      { s{1, 0, 0, 0, 0, 1, 0, 0} },
      { s{1, 0, 1, 0, 1, 0, 1, 0} }
    }
  },
  -- track 2 - snare
  {
    vol = 0.75,
    pitch = false,
    patterns = {
      { s{0} },
      { s{0, 0, 1, 0} }
    }
  },
  -- track 3 - bass
  {
    vol = 0.4,
    pitch = true,
    patterns = {
      {
        s{1, 0, 0, 0, 0, 0, 0, 0},  -- triggers
        s{6, 1, 4, -1} --semitone offset
      },
      {
        s{1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0},  -- triggers
        s{6, 6, 6, 1, 1, 1, 4, 4, 4, -1, -1, -1} --semitone offset
      },
      {
        s{1},  -- triggers
        s{6, 6, 6, 6, 6, 6, 6, 6, 1, 1, 1, 1, 1, 1, 1, 1, 4, 4, 4, 4, 4, 4, 4, 4, -1, -1, -1, -1, -1, -1, -1, -1} --semitone offset
      },
    }
  },
  -- track 3
  {
    vol = 0.25,
    pitch = true,
    patterns = {
      {
        s{0}, 
        s{0}
      },
      {
        s{1, 0, 0, 0, 1, 0, 1, 0},
        s{1, 2, 9, 4, 6, 4, 6, 2}
      },    
      {
        s{1},
        s{1, 2, 4, s{9, 9, 6, 6, 8, 8, 6, 6}}
      }
    }
  }
}

-- use voice 1 as a delay of voice 4
function delay_on()
  softcut.loop(1, 1)
  softcut.enable(1, 1)
  softcut.rec(1, 1)
  softcut.level(1, 0.9)
  softcut.level_cut_cut(4, 1, 0.5)

	softcut.loop_start(1, 300)
	softcut.loop_end(1, 302)
	softcut.position(1, 300)
  	
	softcut.rec_level(1, 1)
	softcut.pre_level(1, 0.65)
	softcut.rate(1, 0.5)
end

function delay_off()
  sc_fn.clear_voice(1)  
  softcut.rec(1, 0)
  softcut.loop(1, 0)
  params:set('voice 1 sample', _path.audio..'nc03-ds/01-bd/01-bd_default-1.flac')
  params:set('level_1', play_seq[1].vol)
end

function cadence_change()
  for i = 1, #play_seq do
    local new_pattern = math.ceil((#play_seq[i].patterns / cadence_max) * cadence)
    if new_pattern ~= play_seq[i].cur_pattern then
      play_seq[i].next_pattern = new_pattern
      play_seq[i].patterns[new_pattern][1]:reset()
      if play_seq[i].pitch then
        play_seq[i].patterns[new_pattern][2]:reset()
      end

      screen_dirty = true
    end
  end
end

function horizon_change()
  params:set('level_5', horizon / 10)
  params:set('level_6', horizon / 10)
end

function start_song()
  lfos[1]:start()
  song = clock.run(
    function()
      local beat_count = 0
      while true do
        clock.sync(1/(relax == 10 and 0.3 or stable and 2 or 3)) 
        beat_count = beat_count + 1
        for i = 1, #play_seq do
          local track = play_seq[i];
          local step_value = track.patterns[track.cur_pattern][1]()
          local p = stable or math.random() > (relax > 0 and 0.5 or 0.3)
          if step_value == 1 and p then
            local semi = track.pitch and track.patterns[track.cur_pattern][2]() or 0
            params:set('semitone_offset_'..i, semi)
            sc_fn.play_slice(i, 1)
          end
          
          if beat_count == 32 then
            if track.next_pattern > 0 then
              track.cur_pattern = track.next_pattern
            end
            track.next_pattern = 0
          end
        end

        -- changes based on beat
        if relax < 10 and beat_count % 2 == 0 then
          draw_step()
        end
        
        -- relaxing
        if relax > 0  and relax < 10 then
          relax = relax + 1
          if horizon < relax then 
            horizon = relax 
            horizon_change()
          end
          if cadence < relax then
            cadence = relax
            cadence_change()
          end
        end

        if beat_count == 32 then
          beat_count = 0
        end
      end
    end
  )
end

function stop_song()
  lfos[1]:stop()
  clock.cancel(song)
  song = nil
  for i = 1, #play_seq do
    play_seq[i].patterns[play_seq[i].cur_pattern][1]:reset()
    if play_seq[i].pitch then
      play_seq[i].patterns[play_seq[i].cur_pattern][2]:reset()
    end
  end
end

------------------------------------------------------------------------
-- drawing
------------------------------------------------------------------------
function draw_screen()
  if screen_dirty then
    redraw()
    screen_dirty = false
  end
end

track = {}
track_m = false
car_pos = 1
function draw_init()
  for i=1, 4 do
    track[i] = {
      road = 1,
      tree = 1,
      tree_x = 0,
      traffic = -1
    }
  end
  track[1].tree = 0
  track[3].tree = 2

  screen_dirty = true
  screen_redraw = metro.init(draw_screen, 1/15, -1)
  screen_redraw:start()
end

function draw_step()
  -- check if all current track sections are straight
  local all_straight = 1
  for i=1, #track do
    if track[i].road ~= 1 then
      all_straight = track[i].road
      break
    end
  end
  
  -- if they are then maybe curve left or right
  local new_track = { road = 1, traffic = -1}
  if all_straight == 1 then
    local n = math.random(10)
    if n < 3 then
      new_track.road = 0
    elseif n > 8 then
      new_track.road = 2
    end
    
    -- tree?
    local t = math.random(10)
    if t < 4 and new_track.road > 0 then
      new_track.tree = 0
    elseif t > 7 and new_track.road < 2 then
      new_track.tree = 2
    end

  else
    -- tree?
    local t = math.random(10)
    if math.random(10) > 8 then
      new_track.tree = all_straight == 0 and 2 or 0
    end
  end
  new_track.tree_x = track[4].tree_x > 0 and 0 or 8
  
  -- traffic?
  if track[4].traffic == -1 and math.random(10) < cadence then
    new_track.traffic = math.random(3) - 1
  end

  table.remove(track, 1)
  table.insert(track, new_track)
  
  -- avoid traffic
  if track[2].traffic == car_pos then
    car_pos = car_pos > 0 and track[1].traffic ~= car_pos - 1 and car_pos - 1 or car_pos + 1
  end
  
  track_m = not track_m
  screen_dirty = true
end

function draw_track()
  local bend = 1
  local x_mod1 = 0
  local x_mod2 = 0 
  for i=0, #track - 1 do
    local y = 64 - (i * 12)
    
    screen.aa(1)
    if bend == 0 then
      x_mod1 = x_mod1 - 4
      x_mod2 = x_mod1 - 4
    elseif bend == 2 then
      x_mod1 = x_mod1 + 4
      x_mod2 = x_mod1 + 4
    elseif track[i+1].road == 1 then
      screen.aa(0)
    end
    
    for x=28, 100, 24 do
      if x == 28 or x == 100 or (i % 2 == 1) == track_m then
        screen.move(x + x_mod1, y)
        if track[i+1].road == 1 then
          screen.line(x + x_mod2, y - 12)
        elseif track[i+1].road == 0 then
          bend = 0
          screen.curve(x - 2, y - 8, x - 4, y - 8, x - 4, y - 12)
        elseif track[i+1].road == 2 then
          bend = 2
          screen.curve(x + 2, y - 8, x + 4, y - 8, x + 4, y - 12)
        end
        screen.stroke()
      end
    end

    -- traffic
    if track[i+1].traffic > -1 then
      screen.display_png(_path.code.."nc03-ds/images/sr_traffic.png", 32 + (track[i+1].traffic * 24) + x_mod1, y - 12)
    end
    
    screen.aa(0)
  end
end

function draw_trees()
  for i=0, #track - 1 do
    local y = 64 - (i * 12)

    if y > 20 + (horizon * 3.6) then
      if track[i+1].tree == 0 then
        screen.display_png(_path.code.."nc03-ds/images/sr_tree.png", 2 + track[i+1].tree_x, y - 16)
      elseif track[i+1].tree == 2 then
        screen.display_png(_path.code.."nc03-ds/images/sr_tree.png", 100 + track[i+1].tree_x, y - 16)
      end
    end
  end
end

function redraw()
  screen.clear()
  screen.level(5)
  
  if relax < 10 then
    draw_track()
  end
  
  -- horizon
  local h = 16 + (horizon * 3.6)
  screen.level(0)
  screen.rect(0, 0, 128, h)
  screen.fill()
  screen.level(5)
  screen.move(0, h)
  screen.line(128, h)
  screen.stroke()
  
  draw_trees()
  
  -- stats
  screen.move(2, 5)
  screen.text("C")
  screen.rect(10, 1, 21, 4)
  screen.stroke()
  screen.level(15)
  screen.rect(10, 1, cadence * 2, 3)
  screen.fill()
  screen.level(5)
  
  screen.move(96, 5)
  screen.text("V")
  screen.rect(104, 1, 21, 4)
  screen.stroke()
  screen.level(15)
  screen.rect(104, 1, volume * 2, 3)
  screen.fill()
  screen.level(5)
  if not stable then
    screen.move(127, 5)
    screen.text("!")
  end
  
  screen.display_png(_path.code.."nc03-ds/images/sr_car.png", 32 + (car_pos * 24), 52)

  screen.update()
end