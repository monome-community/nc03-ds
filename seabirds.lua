-- seabirds
local lattice = require('lattice')
local lfos = require('lfo')
local s = require('sequins')
local cut = require('softcut')

local lat = lattice:new()

local SIZE = 1024

local kicks = {
  s{1, 0, 0.5, 0, 0.75, 0, 0.5, 0, 
    1, 0, 0.5, 0, 0.75, 0, 0.5, 0, 
    1, 0, 0.5, 0, 0.75, 0, 0.5, 0, 
    s{ s{0, 0, 0, 0, 0, 0, 0, 0}:all(), s{1, 0, 0.5, 0, 0.75, 0, 0.5, 0.75}:all()}},
  s{1, 0, 0.25, 1, 0, 0.5, 1, 0.75},
  s{1, 0, 0, 0.5, 0.25, 0.75, 0, 0.25},
  s{0.25, 0.75, 0, 0.5, 0.25, 0.75, 0, 0.5}, 
  s{1, 0, 0.5, 0, 0.75, 0, 
    1, 0, 0.5, 0, 0.75, 0, 
    1, 0, 0.5, 0, 0.75, 0, 
    s{ s{0, 0, 0, 0, 0, 0}:all(), s{1, 0, 0.5, 0, 0.75, 0.75}:all()}},
  s{1, 0, 0.25, 1, 0, 0.5, 1, 0.75},
  s{1, 0, 0, 0.5, 0.25, 0.75, 0, 0.25},
  s{0.25, 0.75, 0, 0.5, 0.25, 0.75, 0, 0.5}, 
  s{1, 0, 0.5, 0, 0.75, 0, 0.5, 0, 
    1, 0, 0.5, 0, 0.75, 0, 0.5, 0, 
    1, 0, 0.5, 0, 0.75, 0, 0.5, 0, 
    s{ s{0, 0, 0, 0, 0, 0, 0, 0}:all(), s{1, 0, 0.5, 0, 0.75, 0, 0.5, 0.75}:all()}},
  s{1, 0, 0.25, 1, 0, 0.5, 1, 0.75},
  s{1, 0, 0, 0.5, 0.25, 0.75, 0, 0.25},
  s{0.25, 0.75, 0, 0.5, 0.25, 0.75, 0, 0.5}, 
  s{1, 0, 0.5, 0, 0.75, 0, 0.5, 0, 
    1, 0, 0.5, 0, 0.75, 0, 0.5, 0, 
    1, 0, 0.5, 0, 0.75, 0, 0.5, 0, 
    s{ s{0, 0, 0, 0, 0, 0, 0, 0}:all(), s{1, 0, 0.5, 0, 0.75, 0, 0.5, 0.75}:all()}},
  s{1, 0, 0.25, 1, 0, 0.5, 1, 0.75},
  s{1, 0, 0, 0.5, 0.25, 0.75, 0, 0.25},
  s{0.25, 0.75, 0, 0.5, 0.25, 0.75, 0, 0.5},   
}

local snares = {
  s{0, 0, 1, 0, 0, 0, 1, 0},
  s{0, 0, 0.5, 0.75, 0, 0.5, 1, 0},
  s{0, 0, 0, 0, 1, 0, 0, 0},
  s{0, 0, 1, 0, 0, 0.75, 0, 0.5},
  s{0, 0, 1, 0, 1, 0},
  s{0, 0, 0.5, 0.75, 0, 0.5, 1, 0},
  s{0, 0, 0, 0, 1, 0, 0, 0},
  s{0, 0, 1, 0, 0, 0.75, 0, 0.5},
  s{0, 0, 1, 0, 0, 0, 1, 0},
  s{0, 0, 0.5, 0.75, 0, 0.5, 1, 0},
  s{0, 0, 0, 0, 1, 0, 0, 0},
  s{0, 0, 1, 0, 0, 0.75, 0, 0.5},
  s{0, 0, 1, 0, 0, 0, 1, 0},
  s{0, 0, 0.5, 0.75, 0, 0.5, 1, 0},
  s{0, 0, 0, 0, 1, 0, 0, 0},
  s{0, 0, 1, 0, 0, 0.75, 0, 0.5},  
}

local hats = {
  s{0.75, 0.25},
  s{0.75, 0.75, 0.25, 0.75, 0.5, 0.75, 0},
  s{0.25, 0.75},
  s{0.75, 0, 0.25, 0.75, 0.5, 0},
  s{0.75, 0.25},
  s{0.75, 0.75, 0.25, 0.75, 0.5, 0.75, 0},
  s{0.25, 0.75},
  s{0.75, 0, 0.25, 0.75, 0.5, 0},
  s{0.75, 0.25},
  s{0.75, 0.75, 0.25, 0.75, 0.5, 0.75, 0},
  s{0.25, 0.75},
  s{0.75, 0, 0.25, 0.75, 0.5, 0},
  s{0.75, 0.25},
  s{0.75, 0.75, 0.25, 0.75, 0.5, 0.75, 0},
  s{0.25, 0.75},
  s{0.75, 0, 0.25, 0.75, 0.5, 0},  
}

local other = {
  s{1, 0, 0.25, 1, 0, 0.5, 1, 0.75},
  s{0, 0, 0, 0, 0, 0, 0, 0.75},
  s{1, 0, 0.25, 1, 0, 0.5, 1, 0.75},
  s{0, 0, 0, 0, 0, 0, 0, 0.75},
  s{1, 0, 0.25, 1, 0, 0.5, 1, 0.75},
  s{1, 0, 0, 0, 0, 0.75},
  s{1, 0, 0.25, 1, 0, 0.5, 1, 0.75},
  s{0, 0, 0, 0, 0, 0, 0, 0.75},
  s{1, 0, 0.25, 1, 0, 0.5, 1, 0.75},
  s{0, 0, 0, 0, 0, 0, 0, 0.75},
  s{1, 0, 0.25, 1, 0, 0.5, 1, 0.75},
  s{0, 0, 0, 0, 0, 0, 0, 0.75},
  s{1, 0, 0.25, 1, 0, 0.5, 1, 0.75},
  s{0, 0, 0, 0, 0, 0, 0, 0.75},
  s{1, 0, 0.25, 1, 0, 0.5, 1, 0.75},
  s{0, 0, 0, 0, 0, 0, 0, 0.75},  
}

samples = {}
local max_sample_duration = 3.5

function load_sample(id, file)

  samples[id] = {}
  if file ~= "-" and file ~= "" then
    local ch, len, rate = audio.file_info(file)
    samples[id].sample_rate = rate

    local import_length = len/rate

    samples[id].start_point = (max_sample_duration+0.5)*id

    if import_length < max_sample_duration then
      samples[id].end_point = samples[id].start_point + import_length
    else
      samples[id].end_point = samples[id].start_point + max_sample_duration
    end

    softcut.buffer_clear_region_channel(1, samples[id].start_point, max_sample_duration, 0, 0)
    softcut.buffer_read_mono(file, 0, samples[id].start_point, import_length, 1, 1, 0, 1)
  end
end


function play_pad(id, voice, amp, rate, dur)
  if amp == nil then amp = 0.5 end
  if rate == nil then rate = 1 end
  if filter_amt == nil then filter_amt = 0 end
  if filter_cutoff == nil then filter_cutoff = 4000 end
  local samp = samples[id]
  cut.enable(voice, 1)
  cut.buffer(voice, 1)
  cut.fade_time(voice, 0.2)
  local start_beats = clock.get_beats()
  clock.run(function()
    while(clock.get_beats() - start_beats < dur) do
      local progress = (clock.get_beats() - start_beats)/dur
      cut.post_filter_dry(voice, 0)
      cut.post_filter_lp(voice, 1)
      cut.post_filter_fc(voice, util.linexp(-1, 1, 1000, 3000, math.sin(2*math.pi*clock.get_beats()%1)))
      cut.level_slew_time(voice, 0.1)
      local randval = math.random()
      local leng = samp.end_point - samp.start_point
      randval = 0.3*randval + 0.05
      local randpos = samp.start_point + randval*leng
      cut.position(voice, randpos)
      cut.pan(voice, math.random() - 0.5)
      cut.rate(voice, rate)
      cut.loop_start(voice, samp.start_point)
      cut.loop_end(voice, samp.end_point)
      cut.level(voice, amp*math.sin(math.pi*progress))
      cut.loop(voice, 0)
      cut.play(voice, 1)
      clock.sleep(0.1 + 0.2 * math.random())
    end
  end)
end

function play_sample(id, voice, amp, pan, rate, filter_amt, filter_cutoff)
  if amp == nil then amp = 0.5 end
  if pan == nil then pan = 0 end
  if rate == nil then rate = 1 end
  if filter_amt == nil then filter_amt = 0 end
  if filter_cutoff == nil then filter_cutoff = 4000 end
  local samp = samples[id]
  cut.enable(voice, 1)
  cut.buffer(voice, 1)
  cut.fade_time(voice, 0.002)
  cut.post_filter_dry(voice, 1-filter_amt)
  cut.post_filter_lp(voice, filter_amt)
  cut.post_filter_fc(voice, filter_cutoff)
  cut.level_slew_time(voice, 0.001)
  cut.position(voice, samp.start_point)
  cut.pan(voice, pan)
  cut.rate(voice, rate)
  cut.loop_start(voice, samp.start_point)
  cut.loop_end(voice, samp.end_point)
  cut.level(voice, amp)
  cut.loop(voice, 0)
  cut.play(voice, 1)
end

function init_samples()
  local names = {
    "01-bd/01-bd_default-1.flac",
    "02-sd/02-sd_default-1.flac",
    "07-hh/07-hh_default-1.flac",
    "05-rs/05-rs_default-1.flac",
    "01-bd/01-bd_default-2.flac",
    "02-sd/02-sd_default-2.flac",
    "07-hh/07-hh_default-2.flac",
    "05-rs/05-rs_default-2.flac",
    "01-bd/01-bd_default-1.flac",
    "04-cp/04-cp_default-1.flac",
    "07-hh/07-hh_default-1.flac",
    "05-rs/05-rs_default-1.flac",
    "01-bd/01-bd_default-2.flac",
    "04-cp/04-cp_default-2.flac",
    "07-hh/07-hh_default-2.flac",
    "05-rs/05-rs_default-2.flac",
    "01-bd/01-bd_default-1.flac",
    "02-sd/02-sd_default-1.flac",
    "07-hh/07-hh_default-1.flac",
    "05-rs/05-rs_default-1.flac",
    "03-tm/03-tm_default-2.flac",
    "02-sd/02-sd_default-2.flac",
    "07-hh/07-hh_default-2.flac",
    "05-rs/05-rs_default-2.flac",
    "01-bd/01-bd_default-1.flac",
    "02-sd/02-sd_default-1.flac",
    "07-hh/07-hh_default-1.flac",
    "05-rs/05-rs_default-1.flac",
    "01-bd/01-bd_default-2.flac",
    "04-cp/04-cp_verb-short.flac",
    "07-hh/07-hh_default-2.flac",
    "05-rs/05-rs_default-2.flac",
    "01-bd/01-bd_default-1.flac",
    "02-sd/02-sd_default-1.flac",
    "07-hh/07-hh_default-1.flac",
    "05-rs/05-rs_default-1.flac",
    "01-bd/01-bd_default-2.flac",
    "02-sd/02-sd_default-2.flac",
    "07-hh/07-hh_default-2.flac",
    "05-rs/05-rs_default-2.flac",
    "01-bd/01-bd_default-1.flac",
    "02-sd/02-sd_default-1.flac",
    "07-hh/07-hh_default-1.flac",
    "05-rs/05-rs_default-1.flac",
    "01-bd/01-bd_default-2.flac",
    "02-sd/02-sd_default-2.flac",
    "07-hh/07-hh_default-2.flac",
    "05-rs/05-rs_default-2.flac",
    "01-bd/01-bd_default-1.flac",
    "02-sd/02-sd_default-1.flac",
    "07-hh/07-hh_mods-2.flac",
    "05-rs/05-rs_verb-short.flac",
    "01-bd/01-bd_verb-long.flac",
    "02-sd/02-sd_default-2.flac",
    "07-hh/07-hh_default-2.flac",
    "05-rs/05-rs_default-2.flac",
    "01-bd/01-bd_default-1.flac",
    "02-sd/02-sd_default-1.flac",
    "05-rs/05-rs_default-1.flac",
    "03-tm/03-tm_verb-short.flac",
    "01-bd/01-bd_default-2.flac",
    "02-sd/02-sd_default-2.flac",
    "07-hh/07-hh_default-1.flac",
    "05-rs/05-rs_default-2.flac",
    "07-hh/07-hh_verb-long.flac",
  }
  for i, name in ipairs(names) do
    local f = _path.audio .. "nc03-ds/"..name
    load_sample(i, f)
  end
end

local steps = {}
for i=1,16,1 do
  local bd = {}
  local sn = {}
  local hh = {}
  local ot = {}
  for j=1,16,1 do
    table.insert(bd, kicks[i]())
    table.insert(sn, snares[i]())
    table.insert(hh, hats[i]())
    table.insert(ot, other[i]())
  end
  table.insert(steps, bd)
  table.insert(steps, sn)
  table.insert(steps, hh)
  table.insert(steps, ot)
  
end

max_water_level = 1.2 + 0.7

function water_level(beat, loc_x, loc_y)
  return (
        0.7*math.sin(16*2*math.pi*(loc_x/SIZE) + 2*math.pi*beat/8) + 
        1.2*math.sin(32*2*math.pi*(loc_y/SIZE) - 2*math.pi*beat/8)
      )
end

function advance()
  local beat = clock.get_beats()
  for i=0,15,1 do
    local bd = steps[4*i+1]
    local sn = steps[4*i+2]
    local hh = steps[4*i+3]
    local ot = steps[4*i+4]
    bd[step] = kicks[i+1]()
    sn[step] = snares[i+1]()
    hh[step] = hats[i+1]()
    ot[step] = other[i+1]()
  end
  step = util.wrap(step + 1, 1, 16)
  local heading_64 = 64*heading/(2*math.pi)
  local heading_64_i = math.floor(heading_64)
  local voices = {heading_64_i-1, heading_64_i, heading_64_i+1, heading_64_i+2}
  local distance = 4
  local values = {{}, {}, {}, {}}
  local four_ahead = util.wrap(step+3, 1, 16)
  for i, v in ipairs(voices) do
    local side = v - heading_64_i + (heading_64 % 1)
    voices[i] = util.wrap(voices[i], 1, 64)
    local loc_x = x + side*math.sin(heading) + distance*math.cos(heading)
    local loc_y = y + side*math.cos(heading) + distance*math.sin(heading)
    local displacement = water_level(beat, loc_x, loc_y)
    values[i].id = util.wrap(v, 1, 64)
    values[i].post = steps[util.wrap(v, 1, 64)][four_ahead]
    values[i].pan = util.clamp(side/2, -1, 1)
    values[i].displacement = displacement
    values[i].difference = math.max((2*max_water_level*values[i].post-max_water_level) + values[i].displacement, 0)
    if values[i].post == 0 then
      values[i].difference = 0
    end
    values[i].ratio = values[i].difference/math.max(max_water_level + values[i].displacement, 0.1)
    -- print(i)
    -- tab.print(values[i])
  end
  -- print(values[1].ratio, values[2].ratio, values[3].ratio, values[4].ratio)
  for i=1,4,1 do
    -- print(values[i].id, i, 0.5*values[i].ratio)
    if values[i].ratio > 0 then
      local filt = math.max(2-values[i].difference, 0)
      local cutoff = util.linexp(0, 2, 20000, 500, filt)
      -- print("filt", filt, "cutoff", cutoff)
      play_sample(values[i].id, i, 0.5*values[i].ratio, values[i].pan, 1, 1, cutoff)
    end
  end
  -- print(step, "s", steps[1][step], steps[1][util.wrap(step+1, 1, 16)], steps[1][util.wrap(step+2, 1, 16)])  
end

function init()
  angle = 0
  heading = 0
  x = 0
  y = 0
  step = 1
  clock.run(function() 
    local c = 1
    clock.sync(8)
    while true do
      clock.sync(1/8)
      if c == 1 then
        advance()
      end
      c = c + 1
      if c > 4 then
        c = 1
      end
      redraw()
    end
  end)
  update_pos = lat:new_pattern{
    division = 1/32,
    action = function()
      local d_heading = -math.sin(angle)/16
      -- if d_heading > math.pi then
      --   d_heading = d_heading - 2*math.pi
      -- end
      heading = (heading + d_heading) % (2*math.pi)
      x = x + math.sin(heading)/32
      y = y + math.cos(heading)/32
      x = x % SIZE
      y = y % SIZE
   end
  }
  init_samples()
  lat:start()
end

local heading_letters = {"N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE", "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"}

function heading_letter()
  local i = util.wrap(util.round(-16*heading/(2*math.pi), 1) + 1, 1, 16)
  return heading_letters[i]
end

function key(n, z)
  -- called when a key is pressed or released
end

function enc(n, d)
  -- called when an encoder is turned
  if n == 2 then
    angle = angle + 0.01 * d
    angle = angle % (2*math.pi)
  end
end

function centered_at(x, y, f)
  screen.translate(x, y)
  f()
  screen.translate(-x, -y)
end

function tilted(angle, f)
  screen.rotate(angle)
  f()
  screen.rotate(-angle)
end


p = true
function redraw()
  -- update screen on each change
  screen.translate(0, 0)
  screen.clear()
  local beat = clock.get_beats()

  -- change numeric value under cursor using:
  -- ctl/cmd + alt/opt + equal (+1)
  -- ctl/cmd + alt/opt + minus (-1)
  -- ctl/cmd + alt/opt + shift + equal (+10)
  -- ctl/cmd + alt/opt + shift + minus (-10)
  screen.move(0, 10)
  screen.text(heading_letter())
  centered_at(64, 32, function()
    tilted(angle, function()
      screen.aa(1)
      screen.line_width(1)

      local height = 5 - 0.5*math.abs(math.sin(math.pi*((beat+1) % 2)/2))
      local direction_64 = (64 * heading / (2 * math.pi))
      local offset = direction_64 % 1
      -- if (beat % 0.5 < 0.1) then
      --   print("step", step, "beat", math.floor((2*beat)%16) + 1)
      -- end
      for i=1,12,1 do
        local distance = i - (2*beat) % 1
        if distance < 2 then
          goto continue
        end
        local fov = distance
        screen.level(util.clamp(math.ceil(16 - 1.2*i), 1, 15))
        local py = util.linlin(0, 2, 0, 45, height/distance)-4
        if py < -38 or py > 38 then
          goto continue
        end
        for j=1,32,0.5 do
          local postline = math.floor(util.wrap(direction_64 - j + 16, 1, 64))
          if i == 4 then
            screen.line_width(2)
          else
            screen.line_width(1)
          end

          local postheight = 2*max_water_level*steps[postline][util.wrap(math.floor((2*beat)%16) + 1 + i, 1, 16)] - max_water_level
          -- if (beat % 0.5 < 0.1) and i > 3 and i < 8 and j == 15 then
          --   print(i, postline, postheight)
          -- end
          local side = util.linlin(1, 32, -64, 64, j + offset)
          local px = util.linlin(-8, 8, -120, 120, side/distance)
          if px < -70 or px > 70 then
            goto innercontinue
          end
          local loc_x = x + side*math.sin(heading) + distance*math.cos(heading)
          local loc_y = y + side*math.cos(heading) + distance*math.sin(heading)
          local displacement = water_level(beat, loc_x, loc_y)
          local p_d_y = util.linlin(-2, 2, -45, 45, displacement/distance)
          local postheight_d_y = util.linlin(-2, 2, -45, 45, postheight/distance)
          screen.move(px, py + p_d_y)
          if p_d_y + postheight_d_y > 0 and j % 1 == 0 then
            screen.line_rel(0, -(p_d_y+postheight_d_y))
          else
            screen.line_rel(0, 1)
          end
          screen.stroke()
          ::innercontinue::
        end
        ::continue::
      end
      -- screen.move(-64, -10)
      -- screen.text("h ".. heading .. " a " .. angle)
      -- screen.move(-64, 0)
      -- screen.text("x ".. x .. " y " .. y)
      p = false
    end)
  end)
  screen.update()
end