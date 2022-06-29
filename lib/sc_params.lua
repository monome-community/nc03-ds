local sc_params = {}

function sc_params.init()

  softcut_offsets = {1,102,204,1,102,204} -- 100 seconds of samples per voice, with 2 seconds of wiggle room
  max_sample_duration = 100
  samples = {}

  for i = 1,softcut.VOICE_COUNT do
    
    samples[i] = {
      sample_count = 0,
      rate_offset = 0
    }
    
    softcut.buffer_clear()
    softcut.buffer(i, i<=3 and 1 or 2)
    softcut.enable(i,0)
    softcut.play(i,1)
    softcut.loop(i,0)
    softcut.fade_time(i,0.0005)
    softcut.loop_start(i,softcut_offsets[i])
    softcut.loop_end(i,softcut_offsets[i]+1) -- will get overridden when we load sample folders, anyway
    softcut.position(i,softcut_offsets[i]+1) -- set to the loop end for each voice, so we aren't playing anything
    softcut.rate(i,1)
    softcut.level_slew_time(i,0.01)
    
    params:add_group("voice ["..i.."]", 55)

    params:add_separator("voice controls")

    params:add{
      type = 'trigger',
      id = "voice "..i.." clear",
      name = "clear samples",
      action =
        function()
          sc_fn.clear_voice(i)
          -- sc_fn.toggle_softcut_params("hide", i)
        end
    }

    params:add_file("voice "..i.." sample folder", "load folder", _path.audio)
    params:set_action("voice "..i.." sample folder",
      function(file)
        -- if file ~= _path.audio and samples[i].sample_count == 0 then -- no longer needed, cuz hiding the param
        if file ~= _path.audio then
          sc_fn.folder_callback(file,i)
          -- sc_fn.toggle_softcut_params("show", i)
          -- for k,v in pairs(sc_lfos.targets) do
          --   params:lookup_param("lfo_"..v..i).options[1] = "off"
          -- end
        elseif file == _path.audio then
          -- sc_fn.toggle_softcut_params("hide", i)
          -- for k,v in pairs(sc_lfos.targets) do
          --   params:lookup_param("lfo_"..v..i).options[1] = "off (load sample first)"
          -- end
        end
      end
    )

    params:add_text("voice "..i.." sample folder text", "", "")
    params:hide("voice "..i.." sample folder text")
    
    params:add{
      type = "control",
      id = "level_"..i,
      name = "level ["..i.."]",
      controlspec = controlspec.new(0, 2.5, 'lin', 0.01, 1, nil, 1/250, nil),
      formatter = function(param) return(util.round(param:get() * 100,1).."%") end,
      action = function(x) softcut.level(i,x) end
    }
    
    params:add{
      type = "control",
      id = "pan_"..i,
      name = "pan ["..i.."]",
      controlspec = controlspec.new(-1, 1, 'lin', 0.01, 0, nil, 1/200, nil),
      formatter = frm.bipolar_as_pan_widget,
      action = function(x) softcut.pan(i,x) end
    }

    params:add{
      type = "control",
      id = "semitone_offset_"..i,
      name = "semitone offset ["..i.."]",
      controlspec = controlspec.new(-24, 24, 'lin', 0.01, 0, 'st', 1/48, nil),
      action = function(x)
        samples[i].rate_offset = math.pow(0.5, -x / 12)
        softcut.rate(i,sc_fn.get_total_pitch_offset(i))
      end
    }

    params:add{
      type = "control",
      id = "pitch_control_"..i,
      name = "pitch control ["..i.."]",
      controlspec = controlspec.new(-12, 12, 'lin', 0.01, 0, nil, 1/240, nil),
      formatter = function(param) return(util.round(param:get(),0.01).."%") end,
      action = function(x)
        softcut.rate(i,sc_fn.get_total_pitch_offset(i))
      end
    }

    params:add{
      type = "binary",
      id = "reverse_"..i,
      name = "reverse ["..i.."]",
      behavior = "toggle",
      action = function(x)
        softcut.rate(i,sc_fn.get_total_pitch_offset(i))
      end
    }

    local filter_bands = {
      {id = "post_filter_lp", name = "lowpass"},
      {id = "post_filter_hp", name = "highpass"},
      {id = "post_filter_bp", name = "bandpass"},
      {id = "post_filter_dry", name = "dry"}
    }
    for k,v in pairs(filter_bands) do
      params:add{
        type = "control",
        id = v.id.."_"..i,
        name = v.name.." ["..i.."]",
        controlspec = controlspec.new(0, 1, 'lin', 0.01, v.name == "dry" and 1 or 0, nil, nil, nil),
        formatter = function(param) return(util.round(param:get() * 100,1).."%") end,
        action = function(x) softcut[v.id](i,x) end
      }
    end
    
    params:add{
      type = "control",
      id = "post_filter_fc_"..i,
      name = "filter cutoff ".."["..i.."]",
      controlspec = controlspec.new(10, 12000, 'exp', 0.01, 12000, 'hz', nil, nil),
      action = function(x) softcut.post_filter_fc(i,x) end
    }

    params:add{
      type = "control",
      id = "post_filter_rq_"..i,
      name = 'filter q '.."["..i.."]",
      controlspec = controlspec.new(0, 100, 'lin', 0.01, 0, nil, nil, nil),
      formatter = function(param) return(util.round(param:get(),1).."%") end,
      action = function(x)
        local scaled = util.linlin(0,100,2.0,0.001,x)
        softcut.post_filter_rq(i,scaled)
      end
    }

    -- 14 params ^

    for k,v in pairs(sc_lfos.targets) do
      local group_name = string.gsub(sc_lfos.specs[v].group_name,"LFOS","LFO RESETS")
      params:add_separator(group_name)
      params:add_option("expand_"..v.."_lfo_"..i, "▶", {"◀","▼"}, 1)
      params:set_action("expand_"..v.."_lfo_"..i,
        function(x)
          if x == 1 then
            params:lookup_param("expand_"..v.."_lfo_"..i).name = "▶"
            for voices = 1,softcut.VOICE_COUNT do
              params:hide("reset_"..v.."_lfo_"..i.."_"..voices)
            end
          elseif x == 2 then
            params:lookup_param("expand_"..v.."_lfo_"..i).name = "▼"
            for voices = 1,softcut.VOICE_COUNT do
              params:show("reset_"..v.."_lfo_"..i.."_"..voices)
            end
          end
          _menu.rebuild_params()
        end
      )
      for voices = 1,softcut.VOICE_COUNT do
        params:add_option("reset_"..v.."_lfo_"..i.."_"..voices, "reset ["..voices.."] on trig", {"no","yes"},1)
      end
    end
  end
  
end

return sc_params