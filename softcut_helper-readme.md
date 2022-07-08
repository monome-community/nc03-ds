# the included softcut helper files

since the prompt for this circle could result in a lot of duplicated effort, we figured it'd be helpful to include some scaffolding for loading samples into softcut, so you can explore the sequencing and manipulation facets of scripting.

## add params with `sc_params`

`lib/sc_params` provides PARAMETERS menu controls for all 6 softcut voices, including buffer allocation. it also moves the bundled samples into the `audio` folder.

instantiate it with `< my softcut params variable >  = include 'lib/sc_params` at the top of your script. then, you can simply add `< my softcut params variable >.init()` to your script's `init` and the controls will populate, eg:

```lua
sc_prm = include 'lib/sc_params' -- param-based controls over softcut

function init()
  sc_prm.init()
end
```

## add functions with `sc_helpers`

`lib/sc_helpers` provides a script functions for different softcut actions, to supplement `sc_params`. once you instantiate it with `< my softcut helper variable > = include 'lib/sc_helpers' at the top of your script, you can:

- pre-load audio files as kits with the following strings: 'default-1', 'default-2', 'fltr-amod-eq', 'fm-lite', 'heavy', 'mods-1', 'mods-2', 'verb-long', 'verb-short'  
  eg. `sc_fn.load_kit('default-1')`
- play a specific voice (1 through 6) with `sc_fn.play_slice(voice,1)`

see [the scarlet script](https://github.com/monome-community/nc03-ds/blob/main/scarlet.lua) for more usage details.