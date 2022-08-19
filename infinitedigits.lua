-- nc03-ds
-- https://github.com/monome-community/nc03-ds
-- https://llllllll.co/t/57649
-- construct an evolving expression of
-- rhythmic time using provided synth drum
-- samples, the new lfo library, and sequins.

s=require("sequins")
lattice=require("lattice")

debounce_sequins=0

function setup_clock()
  -- use lattice for the clock
  local lat=lattice:new()
  pattern=lat:new_pattern{
    action=function(v)
      if debounce_sequins>0 then
        debounce_sequins=debounce_sequins-1
        if debounce_sequins==0 then
          setup_sequins()
        end
      end
      if seqs~=nil then
        local i=1
        local seq=seqs[i]()
        if next(seq)~=nil then

          play(i,seq.sample,seq.len*seq.direction)
        end

      end
    end,
    division=1/16,
  }
  lat:start()
end

function math.sign(x)
  if x<0 then
    return-1
  elseif x>0 then
    return 1
  else
    return 0
  end
end

function setup_sequins()
  print("setup_sequins")
  if seqs==nil then
    seqs={}
    for i=1,6 do
      -- empty sequins
      table.insert(seqs,s{})
    end
  end
  hptns={}
  for i=1,6 do
    local ptns={}
    local ptn={}
    for sn=1,32 do
      local num=params:get(i.."_"..sn)
      -- get sample number from the "10s"
      local sample_num=math.floor(math.abs(num)/10)
      -- get the start from a "2" remainder
      local is_start=math.abs(num)%10==2
      -- get the continuation from a "1" remainder
      local is_continue=math.abs(num)%10==1
      -- get the direction from the sign
      local direction=math.sign(num)
      if num~=0 then
        print(num,sample_num,is_start,is_continue,direction)
      end

      -- check if its a start, add it to the pattern
      if is_start or num==0 then
        if next(ptn)~=nil then
          ptn.len=ptn.stop-ptn.start
          table.insert(ptns,ptn)
        end
        if is_start then
          ptn={start=sn,stop=sn,sample=sample_num,direction=direction}
        else
          ptn={}
        end
      elseif is_continue and next(ptn)~=nil then
        ptn.stop=sn
      end
    end
    table.insert(hptns,ptns)
  end

  if hptns[1]~=nil then
    tab.print(hptns[1])
  end

  -- create sequins from this hptn
  for i=1,6 do
    local seq={}
    for sn=1,32 do
      table.insert(seq,{})
    end
    for _,p in ipairs(hptns) do
      if p.start~=nil then
        tab.print(p)
        seq[p.start]=p
        tab.print(seq[p.start])
      end
    end
    seqs[i]:settable(seq)
  end
end

function setup_parameters()
  -- each parameter composed of 32 beats
  for voice=1,6 do
    for sn=1,32 do
      params:add_number(voice.."_"..sn,"beat "..sn,-20000,20000)
      -- hide the parameters so you don't SEE
      params:hide(voice.."_"..sn)
      -- set an action to reload pattern into sequins
      params:set_action(voice.."_"..sn,function(x)
        debounce_sequins=10
      end)
    end
  end

end

function setup_softcut()
  -- reset softcut
  softcut.reset()

  -- create a for loop to initate the softcut voices
  for i=1,softcut.VOICE_COUNT do
    -- which buffer we are using
    softcut.buffer(i,1)
    -- enable voice
    softcut.enable(i,1)
    -- disable playing
    softcut.play(i,0)
    -- disable looping
    softcut.loop(i,0)
    -- set crossfade time
    softcut.fade_time(i,0.02)
    -- set rate
    softcut.rate(i,1)
    -- set pan
    softcut.pan(i,0)
    -- set slews
    softcut.pan_slew_time(i,0.01)
    softcut.level_slew_time(i,0.01)
    softcut.rate_slew_time(i,0.01)

    -- for each voice, make a parameter to adjust it
    -- (copy things from sc_params.lua)
    params:add_group("VOICE "..i,10)

    params:add{
      type="control",
      id=i.."level",
      name="level",
      controlspec=controlspec.new(0,2.5,'lin',0.01,1,0.01/2.5),
      formatter=function(param) return(util.round(param:get()*100,1).."%") end,
      action=function(x) softcut.level(i,x) end,
    }

    params:add{
      type="control",
      id=i.."pan",
      name="pan",
      controlspec=controlspec.new(0,2.5,'lin',0.01,1,0.01/2.5),
      -- formatter=frm.bipolar_as_pan_widget,
      action=function(x) softcut.level(i,x) end,
    }

    params:add{
      type="control",
      id=i.."rate",
      name="rate ["..i.."]",
      controlspec=controlspec.new(-2,2,'lin',0.125,1,'st',0.125/4),
      action=function(x)
        local rev=params:get(i.."reverse")==0 and 1 or-1
        local rate=params:get(i.."rate")*rev
        print("rate",i,rate)
        softcut.rate(i,rate)
      end
    }

    params:add{
      type="binary",
      id=i.."reverse",
      name="reverse ["..i.."]",
      behavior="toggle",
      action=function(x)
        local rev=params:get(i.."reverse")==0 and 1 or-1
        local rate=params:get(i.."rate")*rev
        print("rate",i,rate)
        softcut.rate(i,rate)
      end
    }

    local filter_bands={
      {id="post_filter_lp",name="lowpass"},
      {id="post_filter_hp",name="highpass"},
      {id="post_filter_bp",name="bandpass"},
    {id="post_filter_dry",name="dry"}}
    for k,v in pairs(filter_bands) do
      params:add{
        type="control",
        id=v.id.."_"..i,
        name=v.name.." ["..i.."]",
        controlspec=controlspec.new(0,1,'lin',0.01,v.name=="dry" and 1 or 0,nil,nil,nil),
        formatter=function(param) return(util.round(param:get()*100,1).."%") end,
        action=function(x) softcut[v.id](i,x) end
      }
    end

    params:add{
      type="control",
      id="post_filter_fc_"..i,
      name="filter cutoff ".."["..i.."]",
      controlspec=controlspec.new(10,12000,'exp',0.01,12000,'hz',nil,nil),
      action=function(x) softcut.post_filter_fc(i,x) end
    }

    params:add{
      type="control",
      id="post_filter_rq_"..i,
      name='filter q '.."["..i.."]",
      controlspec=controlspec.new(0,100,'lin',0.01,0,nil,nil,nil),
      formatter=function(param) return(util.round(param:get(),1).."%") end,
      action=function(x)
        local scaled=util.linlin(0,100,2.0,0.001,x)
        softcut.post_filter_rq(i,scaled)
      end
    }
  end

  params:bang()
end


function setup_samples()
  -- clear the buffer
  softcut.buffer_clear()

  -- create an empty table
  -- GLOBAL table
  samples={}

  -- copy from sc_helpers.lua
  local paths={
    '01-bd',
    '02-sd',
    '03-tm',
    '04-cp',
    '05-rs',
    '06-cb',
    '07-hh',
  }

  -- loop through each path
  for _,folder in ipairs(paths) do
    -- load the folder
    folder=_path.audio.."nc03-ds/"..folder

    -- scan the folder
    local all_files=util.scandir(folder)

    -- get only audio files
    local clean_wavs={}
    for _,fname in ipairs(all_files) do
      -- get pathname filename ext
      local pathname,filename,ext=string.match(fname,"(.-)([^\\/]-%.?([^%.\\/]*))$")
      -- get the full path
      local path=folder.."/"..filename
      -- check if its an audio file
      if string.match(ext,"wav") or string.match(ext,"flac") or string.match(ext,"aiff") then
        table.insert(clean_wavs,path)
      end
    end

    -- collect informaton on each sample
    for _,path in ipairs(clean_wavs) do
      -- get file info
      local ch,len,rate=audio.file_info(path)
      -- get filename
      local pathname,filename,ext=string.match(path,"(.-)([^\\/]-%.?([^%.\\/]*))$")
      table.insert(samples,{
        path=path,
        len=len,
        duration=len/48000,
        filename=filename,
      })
    end

    -- lets actually load the files now into softcut
    -- figure out the total duration of all the samples
    local total_duration=0
    for _,sample in ipairs(samples) do
      total_duration=total_duration+sample.duration
    end
    -- lets figure out the buffer time we have left
    local time_remaining=softcut.BUFFER_SIZE-total_duration-2
    -- and now we can proportion time to each sample
    local time_per_sample=time_remaining/#samples

    -- lets load in each sample into a position
    -- spaced by the calculated time
    local pos=1
    for i,sample in ipairs(samples) do
      print("loading",sample.path,"into pos",pos)
      softcut.buffer_read_mono(sample.path,0,pos,-1,1,1,0,1)
      -- save position of the sample
      samples[i].pos=pos
      -- iterate the position by the size of the sample
      -- and the time per sample
      pos=pos+sample.duration+time_per_sample
    end
  end

  -- that's it! all samples are loaded
end

function play(voice,samplei,sn)
  -- sn: sixteenth notes to PLAY
  -- if negative, start from the start reversed
  print("play",voice,samplei,sn)
  -- figure out the start+end position
  local pos={start=0,stop=1} -- in seconds
  if sn>0 then
    pos.start=samples[samplei].pos
    pos.stop=pos.start+clock.get_beat_sec()/4*math.abs(sn)
  elseif sn<0 then
    pos.stop=samples[samplei].pos
    pos.start=pos.stop+clock.get_beat_sec()/4*math.abs(sn)
  else
    -- sn cannot be 0
    do return end
  end
  if pos.start<0 then
    pos.start=0
  end

  -- setup the loop positions
  softcut.rate(voice,params:get(voice.."rate")*(sn>0 and 1 or-1))
  softcut.play(voice,1)
  softcut.loop_start(voice,(sn>0 and pos.start or pos.stop)-0.5)
  softcut.loop_end(voice,(sn>0 and pos.stop or pos.start)+0.5)
  print(pos.start,pos.stop)
  softcut.position(voice,pos.start)

end


-- norns basic functions
function init()
  setup_softcut()
  setup_samples() -- load in the samples to softcut
  setup_parameters() -- load parameters for patterns
  setup_sequins() -- load the sequins stuff
  setup_clock() -- setup lattice
  print("hello, world")
end

-- runs after you unload a script
function cleanup()

end

-- key function
function key(k,z)

end

-- encoder function
function enc(k,d)

end
-- cause the screen to draw stuff
function redraw()
  screen.clear()
  screen.move(64,32)
  screen.text_center("nc03")
  screen.update()
end
