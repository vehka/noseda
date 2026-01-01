# Core Norns Development Principles

## Norns Platform Overview

Norns is a sound computer by monome that combines:
- **matron**: Lua scripting environment for control and interface
- **crone/supercollider**: Audio synthesis engine (SuperCollider-based)
- **maiden**: Web-based editor and REPL
- Hardware: encoders, keys, screen, audio I/O

## Development Principles

**Simplicity**: Keep code readable and maintainable
**Community**: Follow established norns conventions and patterns
**Documentation**: Comment non-obvious code, provide usage instructions
**Hardware Awareness**: Consider limited screen size (128x64), encoders (3), and keys (3)
**Performance**: Be mindful of CPU usage and real-time audio constraints

## Lua Coding Style for Norns

### File Structure
- Use lowercase filenames: `mylib.lua`, not `MyLib.lua`
- Main script in root: `myscript.lua`
- Libraries in `lib/` directory: `lib/sequencer.lua`
- Data files in `data/` directory (for saving state)

### Naming Conventions
- Variables: lowercase with underscores: `note_value`, `step_count`
- Functions: lowercase with underscores: `update_display()`, `process_midi()`
- Constants: UPPERCASE: `MAX_STEPS = 16`
- Private functions: prefix with underscore: `_internal_helper()`

### Code Style
- Indentation: 2 spaces (norns convention)
- Line length: aim for ~80 characters for readability
- Comments: use `--` for single line, `--[[ ]]--` for blocks
- Local by default: use `local` keyword unless global is needed

## Essential Norns API Patterns

### Lifecycle Functions
```lua
function init()
  -- Called once at script start
end

function cleanup()
  -- Called when script ends
end
```

### Display Functions
```lua
function redraw()
  -- Called to update screen
  screen.clear()
  screen.move(10, 10)
  screen.text("hello")
  screen.update()
end
```

### Input Handlers
```lua
function enc(n, delta)
  -- Encoder input: n=encoder number (1-3), delta=change
end

function key(n, z)
  -- Key input: n=key number (1-3), z=state (1=down, 0=up)
end
```

## SuperCollider for Engines

### Engine Basics
- Extend `CroneEngine` class
- Define in `*.sc` file
- Use `addCommand` to expose parameters to Lua
- Audio output via `Out.ar(context.out_b, signal)`

### Best Practices
- Keep synthesis definitions clear and commented
- Expose useful parameters via commands
- Use sensible parameter ranges and defaults
- Test CPU usage (norns has limited processing power)

## Common Pitfalls

1. **Forgetting to call screen.update()**: Display won't refresh
2. **Global variable pollution**: Use `local` keyword
3. **Not cleaning up resources**: Implement `cleanup()` function
4. **Blocking operations**: Keep functions fast, use clocks for timing
5. **Ignoring nil checks**: Always validate parameters and table access

## Testing and Debugging

- Use `maiden` web interface for development and debugging
- `print()` statements appear in maiden's REPL
- `tab.print(table)` to inspect table contents
- Test on actual hardware when possible (encoder/key feel matters)
- Check CPU usage in SYSTEM > STATS menu

## Resources

- **Local API Docs**: `../norns/doc/` - Complete API reference
- **Community Scripts**: https://norns.community/ - Examples and inspiration
- **Lines Forum**: https://llllllll.co/ - Support and discussion
- **Core Scripts**: `../norns/scripts/` - Reference implementations
