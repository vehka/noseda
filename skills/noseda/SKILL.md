---
name: noseda
description: Develop, debug, test and optimize monome norns scripts, mods and SuperCollider engines. Use when working in a norns project (Lua with init/redraw/enc/key, lib/mod.lua, Engine_*.sc, dust/code), when the user mentions norns, matron, maiden, crone, softcut or dust, or wants to run or test code on a norns device or desktop norns.
---

# Norns Development (NoSEDA)

Guidance for developing monome norns scripts, mods and engines. This file holds
the core principles; the detailed guides are in `references/` and are read only
when they apply. Paths below are relative to this skill's directory (the one
containing this `SKILL.md`).

## Step 1: Detect the component type

Look at the project you are working in (not this skill's directory):

| The project has… | Component | Read |
|---|---|---|
| `lib/mod.lua` | mod | `references/components/mod.md` |
| an `Engine_*.sc` file (root, `lib/` or `sc/`) | engine | `references/components/engine.md` |
| `<dirname>.lua` at the root, or other `*.lua` / `lib/` | script | `references/components/script.md` |

A project can be more than one of these (a script that ships its own engine,
a script with a mod). Read every guide that applies. For a new project, pick
from what the user asks for.

## Step 2: Read the guides that apply

### Patterns (read when the code uses them)

| File | Read when the code… |
|---|---|
| `references/patterns/timing.md` | uses `clock.run` / `clock.sync`, transport callbacks, a step sequencer |
| `references/patterns/midi.md` | sends MIDI notes (`note_on` / `note_off`), chords |
| `references/patterns/params.md` | adds params, separators or groups, or `include()`s other scripts' libraries |

### Tasks (read for the kind of work)

| File | Read when the user wants to… |
|---|---|
| `references/tasks/debug.md` | run, test or debug on a norns (over ssh / wifi) or on desktop norns |
| `references/tasks/optimize.md` | measure or improve performance: timing, CPU, xruns, dropouts |

`scripts/nrepl.py` sends Lua to a norns REPL over websocket (see
`references/tasks/debug.md`). It needs `pip install websocket-client`
(`scripts/requirements.txt`).

Cross-references inside the guides (`tasks/debug.md`, `patterns/midi.md`…) are
relative to `references/`.

## Norns platform overview

Norns is a sound computer by monome that combines:
- **matron**: Lua scripting environment for control and interface
- **crone/supercollider**: Audio synthesis engine (SuperCollider-based)
- **maiden**: Web-based editor and REPL
- Hardware: encoders, keys, screen, audio I/O

## Development principles

- **Simplicity**: Keep code readable and maintainable
- **Community**: Follow established norns conventions and patterns
- **Documentation**: Comment non-obvious code, provide usage instructions
- **Hardware awareness**: Consider limited screen size (128x64), encoders (3), and keys (3)
- **Performance**: Be mindful of CPU usage and real-time audio constraints

## Lua coding style for norns

### File structure
- Use lowercase filenames: `mylib.lua`, not `MyLib.lua`
- Main script in root: `myscript.lua`
- Libraries in `lib/` directory: `lib/sequencer.lua`
- Data files in `data/` directory (for saving state)

### Naming conventions
- Variables: lowercase with underscores: `note_value`, `step_count`
- Functions: lowercase with underscores: `update_display()`, `process_midi()`
- Constants: UPPERCASE: `MAX_STEPS = 16`
- Private functions: prefix with underscore: `_internal_helper()`

### Code style
- Indentation: 2 spaces (norns convention)
- Line length: aim for ~80 characters for readability
- Comments: use `--` for single line, `--[[ ]]--` for blocks
- Local by default: use `local` keyword unless global is needed

## Essential norns API patterns

```lua
function init()
  -- Called once at script start
end

function cleanup()
  -- Called when script ends
end

function redraw()
  -- Called to update screen
  screen.clear()
  screen.move(10, 10)
  screen.text("hello")
  screen.update()
end

function enc(n, delta)
  -- Encoder input: n=encoder number (1-3), delta=change
end

function key(n, z)
  -- Key input: n=key number (1-3), z=state (1=down, 0=up)
end
```

## SuperCollider for engines

- Extend `CroneEngine` class, defined in an `Engine_*.sc` file
- Use `addCommand` to expose parameters to Lua
- Audio output via `Out.ar(context.out_b, signal)`
- Keep synthesis definitions clear and commented
- Use sensible parameter ranges and defaults
- Test CPU usage (norns has limited processing power)

## Common pitfalls

1. **Forgetting to call screen.update()**: Display won't refresh
2. **Global variable pollution**: Use `local` keyword
3. **Not cleaning up resources**: Implement `cleanup()` function
4. **Blocking operations**: Keep functions fast, use clocks for timing
5. **Ignoring nil checks**: Always validate parameters and table access

## Testing and debugging basics

- `print()` output appears in maiden's REPL; `tab.print(table)` inspects a table
- Test on actual hardware when possible (encoder/key feel matters)
- Check CPU usage in SYSTEM > STATS menu
- To run and test code yourself, read `references/tasks/debug.md`

## Norns reference materials

The guides refer to the norns core repository as `../norns/`, i.e. a checkout
next to the project. Check whether it exists there (or elsewhere, e.g.
`~/norns`); if not, use https://github.com/monome/norns and
https://monome.org/docs/norns/ instead, or suggest cloning it.

- **API documentation**: `../norns/doc/`
- **Script examples**: `../norns/scripts/`, https://github.com/tehn/awake
- **Engine examples**: `../norns/sc/engines/` (`Engine_PolyPerc.sc` is a basic template)
- **Mod examples**: https://github.com/monome/norns-example-mod
- **Community**: https://norns.community/ (scripts), https://llllllll.co/ (forum)

## Workflow

1. **Understand the component type** (script, mod, or engine)
2. **Reference existing implementations** in the norns repository or online examples
3. **Follow norns conventions** for file structure and naming
4. **Test on norns hardware or desktop norns** when possible (`references/tasks/debug.md`)
5. **Document clearly** for community sharing

## Important notes

1. **Never modify files in the norns core repository**: only read them for reference
2. **Always check existing norns components** for patterns before implementing
3. **Follow Lua/SuperCollider best practices** appropriate to the component type
4. **Document what needs testing on hardware**: not all functionality can be validated without norns
5. **Use clear, descriptive names** following norns community conventions
