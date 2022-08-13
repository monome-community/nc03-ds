local sc_helpers = {}

local file_load_clock = {}
local file_clear_clock = {}

function sc_helpers.move_samples_into_audio()
  if not util.file_exists(_path.audio..'nc03-ds') then
    print('moving audio')
    os.execute('mv '..norns.state.path..'audio '.._path.audio..'nc03-ds')
  end
end

function sc_helpers.load_kit(which)

  local paths = {
    '01-bd',
    '02-sd',
    '03-tm',
    '04-cp',
    '05-rs',
    '06-cb',
    '07-hh',
  }

  for i = 1,6 do
    print(_path.audio..'nc03-ds/'..paths[i]..'/'..paths[i]..'_'..which..'.flac')
    params:set("voice "..i.." sample", _path.audio..'nc03-ds/'..paths[i]..'/'..paths[i]..'_'..which..'.flac')
  end
end

function sc_helpers.file_callback(file,voice)

  if file_load_clock[voice] then clock.cancel(file_load_clock[voice]) file_load_clock[voice] = nil end
  file_load_clock[voice] = clock.run(
    function()
      softcut.level(voice, 0)
      if file_load_clock[voice] then
        clock.sleep(0.01)
      end
      softcut.enable(voice,1)

      if file ~= "-" and file ~= "" then
        local ch, len, rate = audio.file_info(file)
        samples[voice].sample_rate = rate

        local import_length = len/rate

        samples[voice].start_point = softcut_offsets[voice]

        if import_length < max_sample_duration then
          samples[voice].end_point = samples[voice].start_point + import_length
        else
          samples[voice].end_point = samples[voice].start_point + max_sample_duration
        end

        softcut.buffer_clear_region_channel(softcut_buffers[voice], softcut_offsets[voice], max_sample_duration, 0, 0)
        softcut.buffer_read_mono(file, 0, samples[voice].start_point, import_length, 1, softcut_buffers[voice], 0, 1)
        samples[voice].sample_count = 1
      end

      samples[voice].mode = 'file'
      if file_load_clock[voice] then
        clock.sleep(0.25)
      end
      softcut.level(voice, params:get("level_"..voice))
    end
  )

end

function sc_helpers.folder_callback(file,voice)

  softcut.level(voice, params:get("level_"..voice))
  softcut.enable(voice,1)
  local split_at = string.match(file, "^.*()/")
  local folder = string.sub(file, 1, split_at)
  file = string.sub(file, split_at + 1)
  
  local wavs = util.scandir(folder)
  local clean_wavs = {}
  local sample_iterator = 0
  for index, data in ipairs(wavs) do
    if string.match(data, ".wav") or string.match(data, ".flac") or string.match(data, ".aiff") then
      table.insert(clean_wavs, data)
      sample_iterator = sample_iterator + 1
    end
  end
  print("voice "..voice.." sample count: "..sample_iterator)
  tab.print(clean_wavs)

  softcut.buffer_clear_region_channel(softcut_buffers[voice], softcut_offsets[voice], max_sample_duration, 0, 0)

  local import_length = {}
  
  local total_allowance = max_sample_duration
  
  samples[voice].sample_count = 0
  
  for i = 1, sample_iterator do
    local samp = folder .. clean_wavs[i]
    local ch, len, rate = audio.file_info(samp)
    
    import_length[i] = len/rate
    
    total_allowance = total_allowance - (import_length[i] + 0.25)
    if total_allowance > 0 then
    
      samples[voice][i] = {}
      
      samples[voice][i].sample_rate = rate
      -- put 0.25s in between each sample:
      samples[voice][i].start_point = i == 1 and softcut_offsets[voice] or samples[voice][i-1].end_point + 0.25
      samples[voice][i].end_point = samples[voice][i].start_point + import_length[i]
      softcut.buffer_read_mono(samp, 0, samples[voice][i].start_point, import_length[i], 1, softcut_buffers[voice], 0, 1)
      samples[voice].sample_count = i
    else
      print("sample import time full!")
      break
    end
    
  end
  if samples[voice].sample_count > 0 then
    local parent_path = string.gsub(folder, "/home/we/dust/audio/", "")
    parent_path = util.trim_string_to_width("loaded: "..parent_path,120)
    parent_path = "<"..parent_path..">"
    params:lookup_param("voice "..voice.." sample folder text").name = parent_path
    params:hide("voice "..voice.." sample folder")
    params:show("voice "..voice.." sample folder text")
    _menu.rebuild_params()
    samples[voice].mode = 'folder'
  end
end

function sc_helpers.clear_voice(voice)
  if file_clear_clock[voice] then clock.cancel(file_clear_clock[voice]) end
  file_clear_clock[voice] = clock.run(
    function()
      softcut.level(voice, 0)
      samples[voice].sample_count = 0
      clock.sleep(0.25)
      softcut.buffer_clear_region_channel(softcut_buffers[voice], softcut_offsets[voice], max_sample_duration, 0, 0)
      softcut.enable(voice,0)
      if samples[voice].mode == 'folder' then
        params:lookup_param("voice "..voice.." sample folder").path = _path.audio
        params:lookup_param("voice "..voice.." sample folder text").name = " "
        params:show("voice "..voice.." sample folder")
        params:hide("voice "..voice.." sample folder text")
        _menu.rebuild_params()
      elseif samples[voice].mode == 'file' then
        params:set('voice '..voice..' sample', _path.audio)
      end
    end
  )
end

function sc_helpers.play_slice(voice,slice)
  if samples[voice] and samples[voice].sample_count > 0 then
    slice = util.wrap(slice,1,samples[voice].sample_count)
    samples[voice].current = slice
    softcut.rate(voice,sc_helpers.get_total_pitch_offset(voice, samples[voice].mode))
    local target = samples[voice].mode == 'file' and samples[voice] or samples[voice][slice]
    softcut.loop_start(voice,target.start_point)
    softcut.loop_end(voice,target.end_point)
    local pos;
    if samples[voice].changed_direction then
      pos = samples[voice].reversed and target.end_point-0.001 or target.start_point + 0.001
    else
      pos = samples[voice].reversed and target.end_point or target.start_point
    end
    softcut.position(voice,pos)
  end
end

function sc_helpers.get_total_pitch_offset(voice, mode)
  local total_offset;
  total_offset = samples[voice].semitone_offset
  local sample_rate_compensation;
  local i = (samples[voice].current ~= nil and samples[voice].current or 1)
  if samples[voice].sample_count == 0 then
    return(1)
  else
    local target;
    if mode == 'file' then
      target = samples[voice]
    else
      target = samples[voice][i]
    end
    if (48000/target.sample_rate) > 1 then
      sample_rate_compensation = ((1200 * math.log(48000/target.sample_rate,2))/-100)
    else
      sample_rate_compensation = ((1200 * math.log(target.sample_rate/48000,2))/100)
    end
    total_offset = total_offset + sample_rate_compensation
    local step_rate;
    total_offset = math.pow(0.5, -total_offset / 12) * (samples[voice].reverse)
    if samples[voice].pitch_control ~= 0 then
      total_offset = total_offset + (total_offset * samples[voice].pitch_control)
    end
    if total_offset < 0 then
      if not samples[voice].reversed then
        samples[voice].changed_direction = true
      else
        samples[voice].changed_direction = false
      end
      samples[voice].reversed = true
    else
      if samples[voice].reversed then
        samples[voice].changed_direction = true
      else
        samples[voice].changed_direction = false
      end
      samples[voice].reversed = false
    end
    return (total_offset)
  end
end

function sc_helpers.toggle_softcut_params(state, i)
  params[state](params, "voice "..i.." clear")
  params[state](params, "semitone_offset_"..i)
  params[state](params, "pitch_control_"..i)
  params[state](params, "reverse_"..i)
  params[state](params, "level_"..i)
  params[state](params, "pan_"..i)
  params[state](params, "post_filter_fc_"..i)
  params[state](params, "post_filter_lp_"..i)
  params[state](params, "post_filter_hp_"..i)
  params[state](params, "post_filter_bp_"..i)
  params[state](params, "post_filter_dry_"..i)
  params[state](params, "post_filter_rq_"..i)
  _menu.rebuild_params()
end

return sc_helpers