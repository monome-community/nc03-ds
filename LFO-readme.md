# the included LFO library

modeled after the `params` system, the LFO syntax should feel familiar. after you instantiate it with `< my lfo variable > = include 'lib/lfos'` at the top of your script, you can just build your script's parameters as normal. once your script's parameters are built, you can register up to 8 parameter ID's to a single LFO group and assign custom callbacks to the returned values (optional).

## parameter value modulation

for example, if we have a few already-built synthesis parameters we'd like to place LFOs onto:

```lua
lfos:register('amp', 'SYNTH LFOS')
lfos:register('pw', 'SYNTH LFOS')
lfos:register('cutoff', 'SYNTH LFOS')
lfos:register('pan', 'SYNTH LFOS')
lfos:add_params('SYNTH LFOS')
```

this will create a `SYNTH LFOS` group after your script's initiated parameters, wherein you'll find LFOs for `amp`, `pw`, `cutoff`, and `pan`. the library will dynamically format `min` / `max` ranges, presentation, and awareness of any additional labels based on the registered parameter. once you engage an LFO's `depth` parameter past 0%, navigating to the corresponding parameters within the norns UI will show their values' new sense of movement.

## parameter action modulation

if direct manipulation of the parameter value is not desired, and you simply wish to call the underlying parameter actions while retaining the unmodified starting value, you can pass a `'param action'` string argument during LFO assignment, eg:

```lua
lfos:register('amp', 'SYNTH LFOS', 'param action')
lfos:register('pw', 'SYNTH LFOS', 'param action')
lfos:register('cutoff', 'SYNTH LFOS', 'param action')
lfos:register('pan', 'SYNTH LFOS', 'param action')
lfos:add_params('SYNTH LFOS')
```

this added argument will leave the parameter's starting value undisturbed, which facilitates two things:

1. if the LFO is turned off (or its `depth` is set to 0%) while registered as `'param action'`, it will restore the parameter's initial value
2. each LFO can center its `position` on the 'current value', which requires the value in the params UI to remain static

## additional UI formatting

depending on your needs, you may want to instantiate LFOs in the PARAMETERS menu at certain points in your code's flow.

**to create an 'LFOS' PARAMETERS menu separator to group your LFOs:**

```lua
-- [^built all other parameters above]
lfos:register('voice 1 level', 'levels + panning', 'param action')
lfos:register('voice 2 level', 'levels + panning', 'param action')
lfos:register('voice 1 pan', 'levels + panning', 'param action')
lfos:register('voice 2 pan', 'levels + panning', 'param action')
lfos:add_params('levels + panning', 'LFOS') -- creates an 'LFOS' separator
lfos:register('voice 1 pw', 'synthesis', 'param action')
lfos:register('voice 2 pw', 'synthesis', 'param action')
lfos:register('voice 1 cutoff', 'synthesis', 'param action')
lfos:register('voice 2 cutoff', 'synthesis', 'param action')
lfos:add_params('synthesis') -- no need to add another separator
-- [...]
```

**to create complementary LFO groups alongside your parameters:**

```lua
lfos = include 'lib/lfos'

function init()
  params:add_group('levels',5)
  for i = 1,5 do
    params:add_number('voice '..i..' level', 'voice '..i..' level', 0, 127, 63)
    lfos:register('voice '..i..' level', 'level LFOs', 'param action')
  end
  lfos:add_params('levels LFOs') -- creates a 'levels LFOs' group after the 'level' group
end
```

## additional notes

each LFO group consumes a [metro](https://monome.org/docs/norns/reference/metro), of which a script can have 30 -- so if your script doesn't use any other metros then you can feasibly have up to 240 LFOs (8 per group x 30 metros).

this library is a test-run ahead of submitting it to the main norns codebase -- it's been thoroughly tested, but we're hoping to have it fully proofed with your help. if you run into any troubles with the library, just let us know in the thread!