# (norns/circle/03) dressed in sequins

>a gathering— a group study where participants each create a script according to a prompt. scripts are submitted by an established deadline. discussion and help will be provided to facilitate completion of scripts.
>
>this series will focus on softcut. for an introduction, see softcut studies 61. for general norns scripting, see norns studies 33.
>
> upon completion we will release the pack of scripts as a collection along a bandcamp compilation of captures from each script.
>
>we’ll be here throughout the process to assist everyone in getting scripts working. please ask questions— this is an ideal time to learn.
>
>future prompts will have different parameters. don’t go overboard building out your script with extra functionality— try to stay close to the prompt.

### norns/circle/03 dressed in sequins

construct an evolving expression of rhythmic time using provided synth drum samples, a new library of parameter LFOs, and [sequins](https://monome.org/docs/norns/reference/lib/sequins).

- 7 sample groups with 9 variations are provided
- no USB controllers, no audio input, no engines
- map
	- E1 volume
	- E2 stability
	- E3 horizon
	- K2 relax
	- K3 bind
- visualization of data

parameters are subject to interpretation. “stability” could mean timbral parameter randomization, but perhaps something else. “horizon” could mean the navigation of changes to rhythmic balance, but perhaps something else. “relax” and "bind" could mean a stop/play mechanism, but perhaps something else.

----

notes on the included LFO library:

modeled after the `params` system, the LFO syntax should feel familiar.

after building your script's parameters, you can register up to 8 parameter ID's to a single LFO group and assign custom callbacks to the returned values (optional). for example, if we have a few already-built synthesis parameters we'd like to place LFOs onto:

```lua
lfos:register('amp', 'SYNTH LFOS')
lfos:register('pw', 'SYNTH LFOS')
lfos:register('cutoff', 'SYNTH LFOS')
lfos:register('pan', 'SYNTH LFOS')
lfos:add_params()
```

this will create a `SYNTH LFOS` group after your script's initiated parameters, wherein you'll find LFOs for `amp`, `pw`, `cutoff`, and `pan`. the library will dynamically format `min` / `max` ranges, presentation, and awareness of any additional labels based on the registered parameter. once you engage an LFO's `depth` parameter past 0%, navigating to the corresponding parameters within the norns UI will show their values' new sense of movement.

if direct parameter value manipulation is not desired, and you simply wish to call the underlying parameter actions while retaining the unmodified starting value, you can pass a `'param action'` string argument during LFO assignment, eg:

```lua
lfos:register('amp', 'SYNTH LFOS', 'param action')
lfos:register('pw', 'SYNTH LFOS', 'param action')
lfos:register('cutoff', 'SYNTH LFOS', 'param action')
lfos:register('pan', 'SYNTH LFOS', 'param action')
lfos:add_params()
```

this added argument will leave the parameter's starting value undisturbed, which facilitates two things:

1. if the LFO is turned off (or its `depth` is set to 0%) while registered as `'param action'`, it will restore the parameter's initial value
2. each LFO can center its `position` on the 'current value', which requires the value in the params UI to remain static

this library is a test-run ahead of submitting it to the main norns codebase -- it's been thoroughly tested, but we're hoping to have it fully proofed with your help. if you run into any troubles with the library, just let us know here!

---

deadline: **sept 1**

submit your script by submitting a PR to github: https://github.com/monome-community/nc03-ds (we will help with instructions when the time comes, or feel free to submit early)

record 2-6 minutes of the output of your script using TAPE. feel free to use the built-in reverb and compessor. upload to google drive, dropbox, etc. post link on thread.

---

to get started, go to maiden’s project manager, refresh the collection, and install `nc03-ds`. note, this will take some time to download as it includes some audio files.

if you need a hint getting started, check out `scarlet.lua`
