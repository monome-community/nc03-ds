local sc_params = {}

local sc_fn = include 'lib/sc_helpers'
local frm = require 'formatters'

function sc_params.init()

  sc_fn.move_samples_into_audio()

  softcut_offsets = {1,102,204,1,102,204} -- 100 seconds of samples per voice, with 2 seconds of wiggle room
  softcut_buffers = {1,1,1,2,2,2}
  max_sample_duration = 100
  samples = {}

  params:add_separator("VOICES")

  for i = 1,softcut.VOICE_COUNT do
    
    samples[i] = {
      sample_count = 0,
      rate_offset = 0,
      semitone_offset = 0,
      reverse = 1,
      pitch_control = 0
    }
    
    softcut.buffer_clear()
    softcut.buffer(i, softcut_buffers[i])
    softcut.enable(i,0)
    softcut.play(i,1)
    softcut.loop(i,0)
    softcut.fade_time(i,0.0005)
    softcut.loop_start(i,softcut_offsets[i])
    softcut.loop_end(i,softcut_offsets[i]+1) -- will get overridden when we load sample folders, anyway
    softcut.position(i,softcut_offsets[i]+1) -- set to the loop end for each voice, so we aren't playing anything
    softcut.rate(i,1)
    softcut.pan_slew_time(i,0.01)
    softcut.level_slew_time(i,0.01)
    
    -- params:add_group("voice ["..i.."]", 55)
    params:add_group("voice_"..i, "voice ["..i.."]", 15)

    params:add_separator("voice_"..i.."_controls", "voice controls")

    -- params:add_file("voice "..i.." sample folder", "load folder", _path.audio)
    -- params:set_action("voice "..i.." sample folder",
    --   function(file)
    --     if file ~= _path.audio then
    --       sc_fn.folder_callback(file,i)
    --     elseif file == _path.audio then
    --     end
    --   end
    -- )

    params:add_file("voice "..i.." sample", "load sample", _path.audio)
    params:set_action("voice "..i.." sample",
      function(file)
        if file ~= _path.audio then
          sc_fn.file_callback(file,i)
        elseif file == _path.audio then
        end
      end
    )

    params:add_text("voice "..i.." sample folder text", "", "")
    params:hide("voice "..i.." sample folder text")

    params:add{
      type = 'trigger',
      id = "voice "..i.." clear",
      name = "clear samples",
      action =
        function()
          sc_fn.clear_voice(i)
        end
    }
    
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
      controlspec = controlspec.new(-48, 48, 'lin', 0.01, 0, 'st', 1/96, nil),
      action = function(x)
        samples[i].rate_offset = math.pow(0.5, -x / 12)
        samples[i].semitone_offset = x
        softcut.rate(i,sc_fn.get_total_pitch_offset(i, samples[i].mode))
      end
    }

    params:add{
      type = "control",
      id = "pitch_control_"..i,
      name = "pitch control ["..i.."]",
      controlspec = controlspec.new(-25, 25, 'lin', 0.01, 0, nil, 1/500, nil),
      formatter = function(param) return(util.round(param:get(),0.01).."%") end,
      action = function(x)
        samples[i].pitch_control = x/100
        softcut.rate(i,sc_fn.get_total_pitch_offset(i, samples[i].mode))
      end
    }

    params:add{
      type = "binary",
      id = "reverse_"..i,
      name = "reverse ["..i.."]",
      behavior = "toggle",
      action = function(x)
        samples[i].reverse = x == 1 and -1 or 1
        softcut.rate(i,sc_fn.get_total_pitch_offset(i, samples[i].mode))
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
    
    params:bang()

  end
  
end

return sc_params