-- adapted from code examples
--   by @markeats + @justmat

local frm = require 'formatters'

local lfos = {}

lfos.max_per_metro = 6
lfos.total_count = 0

lfos.groups = {}
lfos.group_iter = 1

lfos.targets = {"level", "pan", "post_filter_fc", "semitone_offset", "pitch_control"} -- STEP 1: add more parameters if you want!
lfos.per_voice = #lfos.targets
lfos.count = lfos.per_voice * softcut.VOICE_COUNT
lfos.update_freq = 128
lfos.freqs = {}
lfos.progress = {}
lfos.values = {}
lfos.rand_values = {}
lfos.loaded = {}
lfos.pre_enable_value = {}

lfos.rates = {1/16,1/8,1/4,5/16,1/3,3/8,1/2,3/4,1,1.5,2,3,4,6,8,16,32,64,128,256,512,1024}
lfos.rates_as_strings = {"1/16","1/8","1/4","5/16","1/3","3/8","1/2","3/4","1","1.5","2","3","4","6","8","16","32","64","128","256","512","1024"}

lfos.ivals = {}

lfos.counter = {}
lfos.update = {}

-- STEP 2: just make sure insert a spec for your LFO, based on its parameter target
lfos.specs = {
  level = {
    -- {min, max, warp, step, default, units, quantum, wrap}
    param_setup = {0, 2.5, nil, 0.01, nil, nil, 1/250, nil},
    -- what value the LFO min/max each start at:
    min_max_defaults = {0,1},
    -- a formatter, to change the display of the parameter value (optional):
    formatter = function(param) return(util.round(param:get() * 100,1).."%") end,
    -- this LFO's group name:
    group_name = 'LEVEL LFOS'
  },
  pan = {
    param_setup = {-1, 1, nil, 0.01, nil, nil, 1/200, nil},
    min_max_defaults = {-1,1},
    formatter = frm.bipolar_as_pan_widget,
    group_name = 'PAN LFOS'
  },
  post_filter_fc = {
    param_setup = {10, 12000, 'exp', 0.01, nil, 'hz', nil, nil},
    min_max_defaults = {10,12000},
    group_name = 'FILTER CUTOFF LFOS'
  },
  semitone_offset = {
    param_setup = {-24, 24, 'lin', 0.01, 0, 'st', 1/48, nil},
    min_max_defaults = {-7,7},
    group_name = 'SEMITONE LFOS'
  },
  pitch_control = {
    param_setup = {-12, 12, 'lin', 0.01, 0, nil, 1/240, nil},
    min_max_defaults = {-12,12},
    formatter = function(param) return(util.round(param:get(),0.01).."%") end,
    group_name = 'PITCH % LFOS'
  }
}

function lfos.params_visiblity(state, i, style)
  params[state](params, "lfo_depth_"..style..i)
  params[state](params, "lfo_mode_"..style..i)
  if state == "show" then
    if params:get("lfo_mode_"..style..i) == 1 then
      params:hide("lfo_free_"..style..i)
      params:show("lfo_beats_"..style..i)
    elseif params:get("lfo_mode_"..style..i) == 2 then
      params:hide("lfo_beats_"..style..i)
      params:show("lfo_free_"..style..i)
    end
  else
    params:hide("lfo_beats_"..style..i)
    params:hide("lfo_free_"..style..i)
  end
  params[state](params, "lfo_shape_"..style..i)
  params[state](params, "lfo_min_"..style..i)
  params[state](params, "lfo_max_"..style..i)
  params[state](params, "lfo_reset_"..style..i)
  params[state](params, "lfo_reset_target_"..style..i)
  _menu.rebuild_params()
end

function lfos.return_to_baseline(i,style)
  -- when an LFO is turned off, the affected parameter will return to its pre-enabled value
  if params:get("lfo_pre_enabled_value_"..style..i) ~= "" then
    params:set(style.."_"..util.wrap(i,1,softcut.VOICE_COUNT),tonumber(params:get("lfo_pre_enabled_value_"..style..i)))
  end
end

function lfos.build_new_group()
  local new_group_table = {available = 6, iter = 1, targets = {}}
  table.insert(lfos.groups, new_group_table)
  lfos.group_iter = lfos.group_iter + 1
end

function lfos.init(param, group_name)

  if #lfos.groups[lfos.group_iter].targets < 6 then
    table.insert(lfos.groups[lfos.group_iter], param)
  else
    lfos.build_new_group()
    table.insert(lfos.groups[lfos.group_iter], param)
  end

  table.insert(lfos.targets, param)

  if group_name ~= nil then

  end

  for k,style in pairs(lfos.targets) do
    -- lfos 1-6: level
    -- lfos 7-12: panning
    -- lfos 13-18: filter cutoff
    -- lfos 19-24: semitone offset
    -- etc etc
    lfos.ivals[style] = {1 + (softcut.VOICE_COUNT*(k-1)), (softcut.VOICE_COUNT * k)}
    lfos.loaded[style] = false
    lfos.add_params(style)
  end
  params:bang()
end

function lfos.add_params(style)
  params:add_group(lfos.specs[style].group_name, 12*softcut.VOICE_COUNT)
  for i = 1,softcut.VOICE_COUNT do
    local _di = i
    params:add_separator("voice [".._di.."]")
    params:add_option("lfo_"..style..i,"lfo",{"off","on"},1)
    params:set_action("lfo_"..style..i,function(x)
      lfos.sync_lfos(i,style)
      if x == 1 then
        lfos.return_to_baseline(i, style)
        lfos.params_visiblity("hide", i, style)
      elseif x == 2 then
        params:set("lfo_pre_enabled_value_"..style..i, params:get(style.."_"..i))
        if samples[_di].sample_count == 0 then
          params:set("lfo_"..style..i, 1)
          lfos.params_visiblity("hide", i, style)
        else
          lfos.params_visiblity("show", i, style)
        end
      end
    end)
    params:add_number("lfo_depth_"..style..i,"depth",0,100,0,function(param) return (param:get().."%") end)
    params:set_action("lfo_depth_"..style..i, function(x)
      if x == 0 then
        lfos.return_to_baseline(i, style)
      end
    end)
    lfos.specs[style].param_setup[5] = lfos.specs[style].min_max_defaults[1]
    params:add{
      type='control',
      id="lfo_min_"..style..i,
      name="lfo min",
      controlspec=controlspec.new(table.unpack(lfos.specs[style].param_setup)),
      formatter =  lfos.specs[style].formatter
    }
    lfos.specs[style].param_setup[5] = lfos.specs[style].min_max_defaults[2]
    params:add{
      type='control',
      id="lfo_max_"..style..i,
      name="lfo max",
      controlspec = controlspec.new(table.unpack(lfos.specs[style].param_setup)),
      formatter = lfos.specs[style].formatter
    }
    params:add_option("lfo_mode_"..style..i, "lfo mode", {"beats","free"},1)
    params:set_action("lfo_mode_"..style..i,
      function(x)
        if x == 1 and params:string("lfo_"..style..i) == "on" then
          params:hide("lfo_free_"..style..i)
          params:show("lfo_beats_"..style..i)
          lfos.freqs[style][i] = 1/(lfos.get_the_beats() * lfos.rates[params:get("lfo_beats_"..style..i)] * 4)
        elseif x == 2 and params:string("lfo_"..style..i) == "on" then
          params:hide("lfo_beats_"..style..i)
          params:show("lfo_free_"..style..i)
          lfos.freqs[style][i] = params:get("lfo_free_"..style..i)
        end
        _menu.rebuild_params()
      end
      )
    params:add_option("lfo_beats_"..style..i, "lfo rate", lfos.rates_as_strings, 9)
    params:set_action("lfo_beats_"..style..i,
      function(x)
        if params:string("lfo_mode_"..style..i) == "beats" then
          lfos.freqs[style][i] = 1/(lfos.get_the_beats() * lfos.rates[x] * 4)
        end
      end
    )
    params:add{
      type='control',
      id="lfo_free_"..style..i,
      name="lfo rate",
      controlspec=controlspec.new(0.001,4,'exp',0.001,0.05,'hz',0.001)
    }
    params:set_action("lfo_free_"..style..i,
      function(x)
        if params:string("lfo_mode_"..style..i) == "free" then
          lfos.freqs[style][i] = x
        end
      end
    )
    params:add_option("lfo_shape_"..style..i, "lfo shape", {"sine","square","random"},1)
    params:add_trigger("lfo_reset_"..style..i, "reset lfo")
    params:set_action("lfo_reset_"..style..i, function(x) lfos.reset_phase(style,i) end)
    params:add_option("lfo_reset_target_"..style..i, "reset lfo to", {"floor","ceiling"}, 1)
    params:hide("lfo_free_"..style..i)
    params:add_text("lfo_pre_enabled_value_"..style..i, "lfo pre-value", nil)
    params:hide("lfo_pre_enabled_value_"..style..i)
  end
  lfos.update[style] = function()
    lfos.process(style)
  end
  lfos.pre_enable_value[style] = {}
  lfos.counter[style] = metro.init(lfos.update[style], 1 / lfos.update_freq):start()
  lfos.progress[style] = {}
  lfos.freqs[style] = {}
  lfos.reset_phase(style)
  lfos.update_freqs(style)
end

function lfos.update_freqs(style)
  for i = 1, softcut.VOICE_COUNT do
    lfos.freqs[style][i] = 1 / util.linexp(1, softcut.VOICE_COUNT, 1, 1, i)
  end
end

function lfos.reset_phase(style,which)
  if which == nil then
    for i = 1, softcut.VOICE_COUNT do
      lfos.progress[style][i] = math.pi * (params:string("lfo_reset_target_"..style..i) == "floor" and 1.5 or 2.5)
    end
  else
    lfos.progress[style][which] = math.pi * (params:string("lfo_reset_target_"..style..which) == "floor" and 1.5 or 2.5)
  end
end

function lfos.get_the_beats()
  return 60 / params:get("clock_tempo")
end

function lfos.sync_lfos(i,style)
  if params:get("lfo_mode_"..style..i) == 1 then
    lfos.freqs[i] = 1/(lfos.get_the_beats() * lfos.rates[params:get("lfo_beats_"..style..i)] * 4)
  else
    lfos.freqs[i] = params:get("lfo_free_"..style..i)
  end
end

function lfos.process(style)
  local delta = (1 / lfos.update_freq) * 2 * math.pi
  -- for i = lfos.ivals[style][1],lfos.ivals[style][2] do
  for i = 1,softcut.VOICE_COUNT do
    -- local _t = util.round(util.linlin(lfos.ivals[style][1],lfos.ivals[style][2],1,softcut.VOICE_COUNT,i))
    local _t = i
    lfos.progress[style][i] = lfos.progress[style][i] + delta * lfos.freqs[style][i]
    local min = params:get("lfo_min_"..style..i)
    local max = params:get("lfo_max_"..style..i)
    if min > max then
      local old_min = min
      local old_max = max
      min = old_max
      max = old_min
    end

    local mid = math.abs(min-max)/2 + min
    local percentage = math.abs(min-max) * (params:get("lfo_depth_"..style..i)/100)

    local scaled_min = min
    local scaled_max = min + percentage
    local value = util.linlin(-1,1,scaled_min,scaled_max,math.sin(lfos.progress[style][i]))
    mid = util.linlin(min,max,scaled_min,scaled_max,mid)

    if value ~= lfos.values[i] and (params:get("lfo_depth_"..style..i)/100 > 0) then
      lfos.values[i] = value
      if params:string("lfo_"..style..i) == "on" then
        if params:string("lfo_shape_"..style..i) == "sine" then
          params:set(style.."_".._t, value)
        elseif params:string("lfo_shape_"..style..i) == "square" then
          local square_value = value >= mid and max or min
          square_value = util.linlin(min,max,scaled_min,scaled_max,square_value) -- new
          params:set(style.."_".._t, square_value)
        elseif params:string("lfo_shape_"..style..i) == "random" then
          local prev_value = lfos.rand_values[i]
          lfos.rand_values[i] = value >= mid and max or min
          local rand_value;
          if prev_value ~= lfos.rand_values[i] then
            rand_value = util.linlin(min,max,scaled_min,scaled_max,math.random(math.floor(min*100),math.floor(max*100))/100) -- new
            params:set(style.."_".._t, rand_value)
          end
        end
      end
    end
  end
end

return lfos