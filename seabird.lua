-- seabird
-- @sixolet
-- 
-- All is sea, and regular 
-- patterns of pylons.
-- You are bird.
-- Fly over pylons and
-- imagine music.
-- 
-- E1 volume: sea level
-- E2 cadence: wave speed
-- E3 horizon: bank your wings
-- K1 stability: mod key for Es
-- K2 relax
-- K3 bind
--
-- Known bug: tempo may not be the same on exit.

local lattice = require('lattice')
local lfos = require('lfo')
local s = require('sequins')
local cut = require('softcut')
local music = require('musicutil')

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

local pads = {}
local pad_vol = {}
local pad_rate = {}
function play_pad(id, voice, amp, rate)
  if amp == nil then amp = 0.5 end
  if rate == nil then rate = 1 end
  if filter_amt == nil then filter_amt = 0 end
  if filter_cutoff == nil then filter_cutoff = 4000 end
  local samp = samples[id]
  cut.enable(voice, 1)
  cut.buffer(voice, 1)
  cut.fade_time(voice, 0.2)
  local start_beats = clock.get_beats()
  pad_vol[voice] = amp
  pad_rate[voice] = rate
  if amp > 0 and pads[voice] == nil then
    print("starting pad")
    pads[voice] = clock.run(function()
      while(true) do
        cut.post_filter_dry(voice, 0)
        cut.post_filter_bp(voice, 1)
        cut.post_filter_fc(voice, util.linexp(-1, 1, 500, 3000, math.sin(2*math.pi*(clock.get_beats()%24)/24)))
        cut.post_filter_rq(voice, 0.8)
        cut.level_slew_time(voice, 0.1)
        local randval = math.random()
        local leng = samp.end_point - samp.start_point
        randval = 0.3*randval + 0.06
        local randpos = samp.start_point + randval*leng
        cut.position(voice, randpos)
        cut.pan(voice, math.random() - 0.5)
        cut.rate(voice, pad_rate[voice])
        cut.loop_start(voice, samp.start_point)
        cut.loop_end(voice, samp.end_point)
        cut.level(voice, pad_vol[voice])
        cut.loop(voice, 0)
        cut.play(voice, 1)
        clock.sleep(0.1 + 0.1 * math.random())
      end
    end)
  elseif amp == 0 then
    cut.level(voice, 0)
    if pads[voice] ~= nil then
      print("stoppping pad")
      clock.cancel(pads[voice])
      pads[voice] = nil
    end
  end
end

function play_sample(id, voice, amp, pan, rate, filter_amt, filter_cutoff)
  if amp == nil then amp = 0.5 end
  if pan == nil then pan = 0 end
  if rate == nil then rate = 1 end
  if filter_amt == nil then filter_amt = 0 end
  if filter_cutoff == nil then filter_cutoff = 4000 end
  local samp = samples[id]
  local start = samp.start_point
  local finish = samp.end_point
  local pos = start
  if angle() > math.pi/2 and angle() < 3*math.pi/2 then
    print('r')
    pos = finish - 0.001
    rate = - rate
  end
  cut.enable(voice, 1)
  cut.buffer(voice, 1)
  cut.fade_time(voice, 0.002)
  cut.post_filter_dry(voice, 1-filter_amt)
  cut.post_filter_lp(voice, filter_amt)
  cut.post_filter_fc(voice, filter_cutoff)
  cut.post_filter_rq(voice, 1)
  cut.level_slew_time(voice, 0.001)
  cut.rate(voice, rate)
  cut.pan(voice, pan)
  cut.loop_start(voice, start)
  cut.loop_end(voice, finish)
  cut.position(voice, pos)
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
    "03-tm/03-tm_verb-short.flac",
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

function max_water_level()
  return math.max((params:get("swell") * (1.2 + 0.7 + 0.3)) + params:get("volume"), 2)
end

function water_level(beat, loc_x, loc_y)
  return (params:get("swell")*(
        0.7*math.sin(16*2*math.pi*(loc_x/SIZE) + params:get("phase")) + 
        1.2*math.sin(32*2*math.pi*(loc_y/SIZE) - params:get("phase")) + 
        0.3*math.sin(64*2*math.pi*(loc_y/SIZE) + params:get("phase"))) -
        params:get("volume"))
end

-- Used on tom, so from B
local intervals = music.intervals_to_ratios({0, 2, 4, 2, 6, 9, 7, 9})
local note_a = 1
local note_b = 1

function advance()
  local beat = clock.get_beats()
  if params:get("bind") == 0 then
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
  end
  local heading_64 = 64*heading/(2*math.pi)
  local heading_64_i = math.floor(heading_64)
  local voices = {heading_64_i-1, heading_64_i, heading_64_i+1, heading_64_i+2}
  local distance = 4
  local values = {{}, {}, {}, {}}
  local four_ahead = util.wrap(step+3, 1, 16)
  local clds = 0
  --local row = util.round(x/32, 1)
  --local col = util.round(y/32, 1)
  local loc_x = x + distance*math.cos(heading)
  local loc_y = y + distance*math.sin(heading)
  note_a, note_b = notes(loc_x, loc_y)
  for i, v in ipairs(voices) do
    local side = v - heading_64_i + (heading_64 % 1)
    voices[i] = util.wrap(voices[i], 1, 64)
    local loc_x = x + distance*math.cos(heading) - side*math.sin(heading) 
    local loc_y = y + distance*math.sin(heading) + side*math.cos(heading)
    clds = math.max(cloudiness(loc_x, loc_y), clds)
    local displacement = water_level(beat, loc_x, loc_y)
    values[i].id = util.wrap(v, 1, 64)
    values[i].post = steps[util.wrap(v, 1, 64)][four_ahead]
    values[i].pan = util.clamp(side/2, -1, 1)
    values[i].displacement = displacement
    values[i].difference = math.max((2*2*values[i].post-max_water_level()) + values[i].displacement, 0)
    if values[i].post == 0 then
      values[i].difference = 0
    end
    values[i].ratio = values[i].difference/math.max(max_water_level() + values[i].displacement, 0.1)
    -- print(i)
    -- tab.print(values[i])
  end
  -- print(values[1].ratio, values[2].ratio, values[3].ratio, values[4].ratio)
  for i=1,4,1 do
    -- print(values[i].id, i, 0.5*values[i].ratio)
    if values[i].ratio > 0 then
      local filt = math.max(2-values[i].difference, 0)
      local cutoff = util.linexp(0, 2, 20000, 1000, filt)
      -- print("filt", filt, "cutoff", cutoff)
      play_sample(values[i].id, i, 0.5*values[i].ratio, values[i].pan, 1/(params:get("relax") + 1), 1, cutoff)
    end
  end
  if clds < 0.01 then clds = 0 end
  --print(clds, note_a, note_b)
  
  play_pad(65, 6, 0.6*clds, 8*note_a)
  play_pad(65, 5, 0.6*clds, 4*note_b)
  
  -- print(step, "s", steps[1][step], steps[1][util.wrap(step+1, 1, 16)], steps[1][util.wrap(step+2, 1, 16)])  
end

function angle()
  return (params:get('horizon') + horizon_lfo:value())%(2*math.pi)
end

global_count = 1

function init()
  clock_param = params:lookup_param("clock_tempo")
  old_clock_get = clock_param.get
  function clock_param:get()
    if params.lookup["swing"] == nil then
      return old_clock_get(self)
    end
    if global_count <= 4 then
      return old_clock_get(self) - params:get("swing")/2
    else
      return old_clock_get(self) + params:get("swing")/2
    end
  end
  function clock_param:bang()
    self.action(self:get())
  end
  params:add_binary("relax", "relax", "momentary", 0)
  params:add_binary("bind", "bind", "momentary", 0)
  params:add_control("volume", "volume", controlspec.new(-2, 2, 'lin', 0, 0))
  params:add_control("horizon", "horizon", controlspec.new(-2*math.pi, 2*math.pi, 'lin', 0, 0, 'rad', 0.001, true))
  params:add_control("cadence", "cadence", controlspec.new(-4, 4, 'lin', 0, 1))
  params:add_control("swell", "swell", controlspec.new(0, 2, 'lin', 0, 1))
  params:add_control("phase", "phase", controlspec.new(0, 2*math.pi, 'lin', 0, 0, 'rad', 0.001, true))
  params:add_control("swing", "cadence instability", controlspec.new(0, 100, 'lin', 0, 0, 'bpm'))
  params:hide("phase")
  
  horizon_lfo = lfos:add{
    min = -math.pi,
    max = math.pi,
    depth = 0,
  }
  horizon_lfo:set('enabled', 1)
  horizon_lfo:add_params("horizon instability", "horizon instability")
  params:set("lfo_horizon instability", 2)
  horizon_lfo:start()
  function horizon_lfo:value()
    return util.linlin(-0.5, 0.5, self.min, self.max, self.depth*(self.raw-0.5))
  end
  heading = 0
  x = 0
  y = 0
  step = 1
  clock.run(function() 
    global_count = 1
    clock.sync(8)
    while true do
      clock.sync(1/8)
      if global_count == 1 or (global_count == 5 and params:get("relax") == 0) then
        advance()
      end
      global_count = global_count + 1
      if global_count > 8 then
        global_count = 1
      end
      if global_count == 1 or global_count == 5 then
        clock_param:bang()
      end
      redraw()
    end
  end)
  update_phase = lat:new_pattern{
    division = 1/96,
    action = function()
      params:set("phase", params:get("phase") + params:get("cadence")*math.pi/96)
    end,
  }
  update_pos = lat:new_pattern{
    division = 1/32,
    action = function()
      local d_heading = -math.sin(angle())/16
      -- if d_heading > math.pi then
      --   d_heading = d_heading - 2*math.pi
      -- end
      heading = (heading - d_heading) % (2*math.pi)
      if params:get("bind") == 0 then
        x = x + math.cos(heading)/8
        y = y + math.sin(heading)/8
        x = x % SIZE
        y = y % SIZE
      end
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

k1 = 0
k2 = 0
k3 = 0

function key(n, z)
  -- called when a key is pressed or released
  if n == 1 then
    k1 = z
  end
  if n == 2 then
    k2 = z
    params:set("relax", z)
  end
  if n == 3 then
    k3 = z
    params:set("bind", z)
  end
end

function enc(n, d)
  -- called when an encoder is turned
  if n == 3 and k1 == 0 then -- horizon
    params:delta('horizon', d)
  elseif n == 3 and k1 == 1 then
    params:delta('lfo_depth_horizon instability', d)
  elseif n == 2 and k1 == 0 then -- cadence
    params:delta('cadence', d)
  elseif n == 2 and k1 == 1 then -- cadence instabilitiy aka swing
    params:delta('swing', d)
  elseif n == 1 and k1 == 0 then -- volume
    params:delta('volume', d)
  elseif n == 1 and k1 == 1 then -- swell
    params:delta('swell', d)
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


function cloudiness(xx, yy)
  local xmisty = 0
  if xx % 32 < 12 then
    xmisty = 1 - ((xx % 32 - 6)^2)/36
  end
  local ymisty = 0
  if yy % 32 < 16 then
    ymisty = 1 - ((xx % 32 - 8)^2)/256
  end
  return xmisty*ymisty
end

function notes(xx, yy)
  local row = util.round(xx/32, 1)
  local col = util.round(yy/32, 1)
  return intervals[util.wrap(row, 1, 8)], intervals[util.wrap(col, 1, 8)]
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
  -- screen.move(30, 10)
  -- screen.text("x "..x .. " ".. math.floor(x/8) % 4)
  -- screen.move(30, 20)
  -- screen.text("y "..y .. " ".. math.floor(y/8) % 4)
  centered_at(64, 32, function()
    tilted(angle(), function()
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
          local steppy2 = step + i - 1
          -- Annoying adjustment for frame coming very slightly after beat.
          if beat % 0.5 < 0.05 then
            steppy2 = steppy2 + 1
          end
          steppy2 = util.wrap(steppy2, 1, 16)
          local postheight = 2*2*steps[postline][steppy2] - max_water_level()
          local side = util.linlin(1, 32, -64, 64, j + offset)
          local px = util.linlin(-8, 8, -120, 120, side/distance)
          if px < -70 or px > 70 then
            goto innercontinue
          end
          local loc_x = x + distance*math.cos(heading) - side*math.sin(heading) 
          local loc_y = y + distance*math.sin(heading) + side*math.cos(heading)
          -- Clouds
          local clds = cloudiness(loc_x, loc_y)
          if distance > 5 and clds > 0.5 then
            local a, b = notes(loc_x, loc_y)
            local p_d_y_c = util.linlin(-2, 2, -45, 45, -6*((a+b)/2)/distance) + 4 * (math.random() - 0.5)
            screen.pixel(px, py+p_d_y_c)
          end
          -- Water
          local displacement = water_level(beat, loc_x, loc_y)
          local p_d_y = util.linlin(-2, 2, -45, 45, displacement/distance)
          local postheight_d_y = util.linlin(-2, 2, -45, 45, postheight/distance)
          screen.move(px, py + p_d_y)
          if i == 4 then
            screen.line_width(2)
          else
            screen.line_width(1)
          end          
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

function cleanup()
  clock_param.get = old_clock_get
  clock_param:set(clock_param.value)
end