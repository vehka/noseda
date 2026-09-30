# Parameter System Patterns and Pitfalls

## Ids and collisions

- `params:add_separator(id, name)`: with one argument the name is also the
  id. Uppercase section names like "REVERB" or "COMPRESSOR" are the ids of
  norns' own system param groups, so norns prints `separator ID <REVERB>
  collides with a non-separator parameter, will not overwrite` on every load.
  (The separator still shows; only the id lookup keeps pointing at the system
  group.) Give script separators prefixed ids:
  `params:add_separator("myscript_reverb", "REVERB")`.
- The same goes for groups (`add_group(id, name, n)`) and every param id:
  prefix them with the script name.
- Check the load output for `collides`, `ID collision` and `clobbering`
  after changing params.

## Groups

- `params:add_group(id, name, n)`: `n` must equal the number of params
  (including separators) added right after it. If it's wrong, the menu nests
  the wrong params. Count the adds in the function that fills the group, and
  watch for adds inside `if` blocks.
- Groups can't be nested.
- Grouping hundreds of params (e.g. per-sample-slot params) into one group
  each makes the PARAMS menu usable, and doesn't change param ids, so psets
  are unaffected.

## Optional dependencies

`include()` of a missing file stops the script from loading with
`MISSING INCLUDE`. For an optional library from another script folder:

```lua
local lib = util.file_exists(_path.code .. "otherlib/lib/otherlib.lua")
  and include("otherlib/lib/otherlib") or nil
-- later: only add the related params/features when lib is available
if lib then params:add_option(...) end
```

Before relying on a third-party library, check its license: without one it
can't be copied (vendored) into the script.

## Caching param values for hot paths

```lua
local jf_enabled = false
params:add_option("jf", "jf output", {"no", "yes"}, 1)
params:set_action("jf", function(x) jf_enabled = (x == 2) end)
```

The action runs on `params:bang()` and on pset load, so the local stays in
sync. It saves a `params:get()` on every tick.

## Testing param changes

In a test harness, `params.set` can be wrapped for timing or logging.
`params` is a ParamSet instance and `set` is a class method, so
`params.set = nil` removes the wrapper again. (MIDI vport methods are
different; see `patterns/midi.md`.)
