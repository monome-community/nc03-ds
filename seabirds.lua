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
  s{0, 0, 1, 0, 0, 0, 1, 0},
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
  s{0, 0, 0, 0, 0, 0, 0, 0.75},
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


function play_sample(id, voice, amp, rate)
  if amp == nil then amp = 0.5 end
  if rate == nil then rate = 1 end
  local samp = samples[id]
  cut.enable(voice, 1)
  cut.buffer(voice, 1)
  cut.position(voice, samp.start_point)
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
    "07-hh/07-hh_default-1.flac",
    "05-rs/05-rs_default-1.flac",
    "01-bd/01-bd_default-2.flac",
    "02-sd/02-sd_default-2.flac",
    "07-hh/07-hh_default-2.flac",
    "05-rs/05-rs_default-2.flac",    
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
  local voices = {heading_64_i-1, heading_64, heading_64+1, heading_64+2}
  local distance = 4
  for i, x in ipairs(voices) do
    local side = x - heading_64_i + (heading_64 % 1)
    voices[i] = util.wrap(voices[i], 1, 64)
    local loc_x = x + side*math.sin(heading) + distance*math.cos(heading)
    local loc_y = y + side*math.cos(heading) + distance*math.sin(heading)
    displacement = water_level(beat, loc_x, loc_y)
  end

  local four_ahead = util.wrap(step+4, 1, 16)
  local values = {steps[voices[1]][four_ahead], steps[voices[2]][four_ahead], steps[voices[3]][four_ahead], steps[voices[4]][four_ahead]}
  tab.print(values)
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

          local postheight = 2*steps[postline][util.wrap(math.floor((2*beat)%16) + 1 + i, 1, 16)] - 1
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
          local displacement = (
            0.7*math.sin(16*2*math.pi*(loc_x/SIZE) + 2*math.pi*beat/8) + 
            1.2*math.sin(32*2*math.pi*(loc_y/SIZE) - 2*math.pi*beat/8)
          )
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