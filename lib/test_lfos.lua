-- adapted from code examples
--   by @markeats + @justmat

local frm = require 'formatters'

local lfos = {}

lfos.max_per_metro = 6

function lfos.new_table()
  return
  {
    available = lfos.max_per_metro,
    iter = 1,
    parent_group = nil,
    targets = {},
    progress = {},
    freqs = {},
    values = {},
    rand_values = {},
    update = {},
    pre_enable_value = {},
    counter = nil,
    param_types = {},
  }
end

lfos.groups = { lfos.new_table() }
lfos.parent_groups = {}
lfos.group_iter = 1

lfos.targets = {"level", "pan", "post_filter_fc", "semitone_offset", "pitch_control"} -- STEP 1: add more parameters if you want!
lfos.per_voice = #lfos.targets
lfos.update_freq = 128

lfos.rates = {1/16,1/8,1/4,5/16,1/3,3/8,1/2,3/4,1,1.5,2,3,4,6,8,16,32,64,128,256,512,1024}
lfos.rates_as_strings = {"1/16","1/8","1/4","5/16","1/3","3/8","1/2","3/4","1","1.5","2","3","4","6","8","16","32","64","128","256","512","1024"}

lfos.main_header_added = false

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

function lfos.params_visiblity(state, group, i)
  params[state](params, "lfo_position_"..group.."_"..i)
  params[state](params, "lfo_depth_"..group.."_"..i)
  params[state](params, "lfo_mode_"..group.."_"..i)
  if state == "show" then
    if params:get("lfo_mode_"..group.."_"..i) == 1 then
      params:hide("lfo_free_"..group.."_"..i)
      params:show("lfo_beats_"..group.."_"..i)
    elseif params:get("lfo_mode_"..group.."_"..i) == 2 then
      params:hide("lfo_beats_"..group.."_"..i)
      params:show("lfo_free_"..group.."_"..i)
    end
  else
    params:hide("lfo_beats_"..group.."_"..i)
    params:hide("lfo_free_"..group.."_"..i)
  end
  params[state](params, "lfo_shape_"..group.."_"..i)
  params[state](params, "lfo_min_"..group.."_"..i)
  params[state](params, "lfo_max_"..group.."_"..i)
  params[state](params, "lfo_reset_"..group.."_"..i)
  params[state](params, "lfo_reset_target_"..group.."_"..i)
  _menu.rebuild_params()
end

function lfos.return_to_baseline(group,i)
  -- when an LFO is turned off, the affected parameter will return to its pre-enabled value
  if params:get("lfo_pre_enabled_value_"..group.."_"..i) ~= "" then
    params:set(lfos.groups[group].targets[i],tonumber(params:get("lfo_pre_enabled_value_"..group.."_"..i)))
  end
end

function lfos.build_new_group()
  table.insert(lfos.groups, lfos.new_table())
  lfos.group_iter = lfos.group_iter + 1
end

function lfos.init(param, parent_group)

  if #lfos.groups[lfos.group_iter].targets < lfos.max_per_metro then
    table.insert(lfos.groups[lfos.group_iter].targets, param)
    lfos.groups[lfos.group_iter].available = lfos.groups[lfos.group_iter].available - 1
  else
    lfos.build_new_group()
    table.insert(lfos.groups[lfos.group_iter].targets, param)
    lfos.groups[lfos.group_iter].available = lfos.groups[lfos.group_iter].available - 1
  end

  lfos.groups[lfos.group_iter].parent_group = parent_group
  if parent_group ~= nil then
    if lfos.parent_groups[parent_group] == nil then
      lfos.parent_groups[parent_group] = {}
    end
    table.insert(lfos.parent_groups[parent_group], param)
  end

end

function lfos.add_params(parent_group, reveal_condition)

  if not lfos.main_header_added then
    params:add_separator("LFOS")
    lfos.main_header_added = true
  end

  if lfos.parent_groups[parent_group] ~= nil then
    print(parent_group)
    params:add_group("LFO: "..parent_group, 12 * tab.count(lfos.parent_groups[parent_group]))
  end

  for group = 1,lfos.group_iter do

    for i = 1,#lfos.groups[group].targets do

      lfos.groups[group].param_types[i] = params:lookup_param(lfos.groups[group].targets[i]).t

      if lfos.parent_groups[parent_group] == nil then
        params:add_group("LFO: "..params:lookup_param(lfos.groups[group].targets[i]).name, 11)
      else
        params:add_separator(params:lookup_param(lfos.groups[group].targets[i]).name)
      end
      params:add_option("lfo_"..group.."_"..i,"lfo",{"off","on"},1)
      params:set_action("lfo_"..group.."_"..i,function(x)
        lfos.sync_lfos(group, i)
        if x == 1 then
          lfos.return_to_baseline(group, i)
          lfos.params_visiblity("hide", group, i)
        elseif x == 2 then
          params:set("lfo_pre_enabled_value_"..group.."_"..i, params:get(lfos.groups[group].targets[i]))
          if reveal_condition ~= nil then
            if reveal_condition then
              params:set("lfo_"..group.."_"..i, 1)
              lfos.params_visiblity("hide", group, i)
            else
              lfos.params_visiblity("show", group, i)
            end
          else
            lfos.params_visiblity("show", group, i)
          end
        end
      end)
      params:add_number("lfo_depth_"..group.."_"..i,"depth",0,100,0,function(param) return (param:get().."%") end)
      params:set_action("lfo_depth_"..group.."_"..i, function(x)
        if x == 0 then
          lfos.return_to_baseline(group, i)
        end
      end)

      params:add{
        type='control',
        id="lfo_min_"..group.."_"..i,
        name="lfo min",
        controlspec = lfos.get_spec(group,i,"min").spec,
        formatter =  lfos.get_spec(group,i).formatter
      }

      params:add{
        type='control',
        id="lfo_max_"..group.."_"..i,
        name="lfo max",
        controlspec = lfos.get_spec(group,i,"max").spec,
        formatter = lfos.get_spec(group,i).formatter
      }

      params:add_option("lfo_position_"..group.."_"..i, "lfo position", {"from current", "from min", "from center", "from max"},1)

      params:add_option("lfo_mode_"..group.."_"..i, "lfo mode", {"beats","free"},1)
      params:set_action("lfo_mode_"..group.."_"..i,
        function(x)
          if x == 1 and params:string("lfo_"..group.."_"..i) == "on" then
            params:hide("lfo_free_"..group.."_"..i)
            params:show("lfo_beats_"..group.."_"..i)
            lfos.groups[group].freqs[i] = 1/(lfos.get_the_beats() * lfos.rates[params:get("lfo_beats_"..group.."_"..i)] * 4)
          elseif x == 2 and params:string("lfo_"..group.."_"..i) == "on" then
            params:hide("lfo_beats_"..group.."_"..i)
            params:show("lfo_free_"..group.."_"..i)
            lfos.groups[group].freqs[i] = params:get("lfo_free_"..group.."_"..i)
          end
          _menu.rebuild_params()
        end
        )
      params:add_option("lfo_beats_"..group.."_"..i, "lfo rate", lfos.rates_as_strings, 9)
      params:set_action("lfo_beats_"..group.."_"..i,
        function(x)
          if params:string("lfo_mode_"..group.."_"..i) == "beats" then
            lfos.groups[group].freqs[i] = 1/(lfos.get_the_beats() * lfos.rates[x] * 4)
          end
        end
      )
      params:add{
        type='control',
        id="lfo_free_"..group.."_"..i,
        name="lfo rate",
        controlspec=controlspec.new(0.001,4,'exp',0.001,0.05,'hz',0.001)
      }
      params:set_action("lfo_free_"..group.."_"..i,
        function(x)
          if params:string("lfo_mode_"..group.."_"..i) == "free" then
            lfos.groups[group].freqs[i] = x
          end
        end
      )
      params:add_option("lfo_shape_"..group.."_"..i, "lfo shape", {"sine","square","random"},1)
      params:add_trigger("lfo_reset_"..group.."_"..i, "reset lfo")
      params:set_action("lfo_reset_"..group.."_"..i, function(x) lfos.reset_phase(group,i) end)
      params:add_option("lfo_reset_target_"..group.."_"..i, "reset lfo to", {"floor","ceiling"}, 1)
      params:hide("lfo_free_"..group.."_"..i)
      params:add_text("lfo_pre_enabled_value_"..group.."_"..i, "lfo pre-value", nil)
      params:hide("lfo_pre_enabled_value_"..group.."_"..i)
    end
    
    params:bang()

    lfos.groups[group].update = function()
      lfos.process(group)
    end

    lfos.groups[group].counter = metro.init(lfos.groups[group].update, 1 / lfos.update_freq):start()

    lfos.reset_phase(group)
    lfos.update_freqs(group)
  end

end

function lfos.get_spec(group,i,bound)
  local lfo_target = lfos.groups[group].targets[i]
  local param_spec = params:lookup_param(lfo_target)

  -- number:
  if param_spec.t == 1 then
    return {
      spec = controlspec.new(
        param_spec.min,
        param_spec.max,
        'lin',
        0,
        (bound == nil and param_spec.value or (bound == 'min' and param_spec.min or param_spec.max)),
        nil,
        (param_spec.t == 1 and 1/(param_spec.max - param_spec.min) or 1),
        param_spec.wrap
      ),
      formatter = function(param) return(
        (util.round(param:get(),1))
      ) end
    }
  -- option:
  elseif param_spec.t == 2 then
    return {
      spec = controlspec.new(
        1,
        param_spec.count,
        'lin',
        1,
        (bound == nil and param_spec.value or (bound == 'min' and 1 or param_spec.count)),
        nil,
        1/(param_spec.count-1)
      ),
      formatter = function(param) return(
        param_spec.options[param:get()]
      ) end
    }
  -- control:
  elseif param_spec.t == 3 then
    return {
      spec = controlspec.new(
        param_spec.controlspec.minval,
        param_spec.controlspec.maxval,
        param_spec.controlspec.warp,
        param_spec.controlspec.step,
        (bound == nil and param_spec.controlspec.default or (bound == 'min' and param_spec.controlspec.minval or param_spec.controlspec.maxval)),
        param_spec.controlspec.wrap
      ),
      formatter = param_spec.formatter
    }
  -- taper:
  elseif param_spec.t == 5 then
    return {
      spec = controlspec.new(
        (param_spec.t == 1 and param_spec.min or 1),
        (param_spec.t == 1 and param_spec.max or param_spec.count),
        'lin',
        0,
        (bound == nil and param_spec.value or (bound == 'min' and param_spec.min or param_spec.max)),
        nil,
        (param_spec.t == 1 and 1/(param_spec.max - param_spec.min) or 1),
        param_spec.wrap
      ),
      formatter = function(param)
        local v = param:get()
        local absv = math.abs(v)
      
        if absv >= 100 then
          format = "%.0f "..string.gsub(self.units, "%%", "%%%%")
        elseif absv >= 10 then
          format = "%.1f "..string.gsub(self.units, "%%", "%%%%")
        elseif absv >= 1 then
          format = "%.2f "..string.gsub(self.units, "%%", "%%%%")
        elseif absv >= 0.001 then
          format = "%.3f "..string.gsub(self.units, "%%", "%%%%")
        else
          format = "%.0f "..string.gsub(self.units, "%%", "%%%%")
        end
      
        return string.format(format, v)
      end
    }
  -- binary:
  elseif param_spec.t == 9 then
    return {
      spec = controlspec.new(
        0,
        1,
        'lin',
        0,
        param_spec.value,
        nil,
        1,
        nil
      ),
      formatter = function(param) return(
        param:get() == 1 and "on" or "off")
      end
    }
  end
end

function lfos.update_freqs(group)
  for i = 1,#lfos.groups[group].targets do
    lfos.groups[group].freqs[i] = 1 / util.linexp(1, #lfos.groups[group].targets, 1, 1, i)
  end
end

function lfos.reset_phase(group,which)
  if which == nil then
    for i = 1, #lfos.groups[group].targets do
      lfos.groups[group].progress[i] = math.pi * (params:string("lfo_reset_target_"..group.."_"..i) == "floor" and 1.5 or 2.5)
    end
  else
    lfos.groups[group].progress[which] = math.pi * (params:string("lfo_reset_target_"..group.."_"..which) == "floor" and 1.5 or 2.5)
  end
end

function lfos.get_the_beats()
  return 60 / params:get("clock_tempo")
end

function lfos.sync_lfos(group, i)
  if params:get("lfo_mode_"..group.."_"..i) == 1 then
    lfos.groups[group].freqs[i] = 1/(lfos.get_the_beats() * lfos.rates[params:get("lfo_beats_"..group.."_"..i)] * 4)
  else
    lfos.groups[group].freqs[i] = params:get("lfo_free_"..group.."_"..i)
  end
end

function lfos.process(group)
  local delta = (1 / lfos.update_freq) * 2 * math.pi
  local lfo_parent = lfos.groups[group]
  for i = 1,#lfo_parent.targets do
    
    local _t = i
    lfo_parent.progress[i] = lfo_parent.progress[i] + delta * lfo_parent.freqs[i]
    local min = params:get("lfo_min_"..group.."_"..i)
    local max = params:get("lfo_max_"..group.."_"..i)
    if min > max then
      local old_min = min
      local old_max = max
      min = old_max
      max = old_min
    end

    local mid = math.abs(min-max)/2 + min
    local percentage = math.abs(min-max) * (params:get("lfo_depth_"..group.."_"..i)/100)

    local scaled_min = min
    local scaled_max = min + percentage
    local value = util.linlin(-1,1,scaled_min,scaled_max,math.sin(lfo_parent.progress[i]))
    mid = util.linlin(min,max,scaled_min,scaled_max,mid)

    if value ~= lfo_parent.values[i] and (params:get("lfo_depth_"..group.."_"..i)/100 > 0) then
      lfo_parent.values[i] = value
      if params:string("lfo_"..group.."_"..i) == "on" then
        if params:string("lfo_position_"..group.."_"..i) == 'from center' then
          mid = math.abs(min-max)/2 + min
          local centroid_mid = (mid) * (params:get("lfo_depth_"..group.."_"..i)/100)
          scaled_min = mid - centroid_mid
          scaled_max = mid + centroid_mid
          value = util.linlin(-1,1,scaled_min, scaled_max, math.sin(lfo_parent.progress[i]))
        elseif params:string("lfo_position_"..group.."_"..i) == 'from max' then
          local _mid = mid
          mid = max - mid
          value = max - value
          scaled_min = max
          scaled_max = math.abs(scaled_min - scaled_max)
        elseif params:string("lfo_position_"..group.."_"..i) == 'from current' then
          local centroid_mid = (mid) * (params:get("lfo_depth_"..group.."_"..i)/100)
          scaled_min = tonumber(params:get("lfo_pre_enabled_value_"..group.."_"..i)) - centroid_mid
          scaled_max = tonumber(params:get("lfo_pre_enabled_value_"..group.."_"..i)) + centroid_mid
          value = util.linlin(-1,1,scaled_min, scaled_max, math.sin(lfo_parent.progress[i]))
        end
        if params:string("lfo_shape_"..group.."_"..i) == "sine" then
          if lfo_parent.param_types[i] == 1 or lfo_parent.param_types[i] == 2 or lfo_parent.param_types[i] == 9 then
            value = util.round(value,1)
          end
          params:set(lfo_parent.targets[i], value)
        elseif params:string("lfo_shape_"..group.."_"..i) == "square" then
          local square_value = value >= mid and max or min
          square_value = util.linlin(min,max,scaled_min,scaled_max,square_value)
          print(
            "min: "..min,
            "max: "..max,
            "scaled min: "..scaled_min,
            "scaled max: "..scaled_max,
            "square val: "..square_value,
            "compare: "..(value >= mid and max or min)
          )
          params:set(lfo_parent.targets[i], square_value)
        elseif params:string("lfo_shape_"..group.."_"..i) == "random" then
          local prev_value = lfo_parent.rand_values[i]
          lfo_parent.rand_values[i] = value >= mid and max or min
          local rand_value;
          if prev_value ~= lfo_parent.rand_values[i] then
            rand_value = util.linlin(min,max,scaled_min,scaled_max,math.random(math.floor(min*100),math.floor(max*100))/100)
            if lfo_parent.param_types[i] == 1 or lfo_parent.param_types[i] == 2 or lfo_parent.param_types[i] == 9 then
              rand_value = util.round(rand_value,1)
            end
            params:set(lfo_parent.targets[i], rand_value)
          end
        end
      end
    end
  end
end

return lfos