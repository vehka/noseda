# MoNoSDA - Modular Norns Script Development Assistant

A modular prompt library for developing monome norns scripts, mods, and engines using agentic AI.

## What is MoNoSDA?

MoNoSDA provides structured prompts to help AI coding assistants (like Claude Code) understand norns development patterns and best practices. It automatically detects whether you're working on a script, mod, or engine and loads the appropriate guidance.

## File Structure

```
├── AGENTS.md                        # Main orchestrator file
├── CLAUDE.md                        # Redirect to AGENTS.md
├── README.md                        # This file
├── TASKS.md                         # Roadmap for extensive version
├── tools/
│   └── nrepl.py                     # Send Lua to a norns REPL over websocket
└── .prompts/
    ├── core/
    │   └── base-instructions.md     # Core norns development principles
    ├── components/
    │   ├── script.md                # Script development guide
    │   ├── mod.md                   # Mod development guide
    │   └── engine.md                # Engine development guide
    ├── patterns/
    │   ├── timing.md                # clock loops, transport, tick budget
    │   ├── midi.md                  # note-off bookkeeping, testing MIDI output
    │   └── params.md                # id collisions, groups, optional includes
    └── tasks/
        ├── debug.md                 # testing on a norns over wifi and on desktop norns
        └── optimize.md              # measuring performance, xruns, fair comparisons
```

## Norns Core Repository

The norns core repository should be cloned alongside this repository for reference:

```
../norns/          # norns core repository
./                 # This norns project repository
```

## Usage

### Setup

1. **Clone MoNoSDA**
   ```bash
   git clone https://github.com/your-org/monosda.git mynornsproject
   cd mynornsproject
   ```

2. **Clone norns for reference** (optional but recommended)
   ```bash
   cd ..
   git clone https://github.com/monome/norns.git
   ```

Your directory structure:
```
.
├── norns/              # norns core (reference)
└── mynornsproject/     # Your project with MoNoSDA
    ├── AGENTS.md
    └── .prompts/
```

3. **Start Claude Code** from your project directory

### What Gets Loaded

MoNoSDA automatically detects your component type and loads relevant guides:

- **Script Project**: Loads base-instructions.md + script.md
- **Mod Project** (has `lib/mod.lua`): Loads base-instructions.md + mod.md
- **Engine Project** (has `*.sc` files): Loads base-instructions.md + engine.md
- **Patterns** (timing, MIDI, params) load when the code uses them
- **Tasks** load for the kind of work: `debug.md` for running and testing on a
  norns or desktop norns, `optimize.md` for performance work

### Example Prompts

> "Help me create a simple sequencer script for norns"

> "I want to create a mod that adds a global metronome to all scripts"

> "Build a polyphonic FM synthesis engine"

## Supported Component Types

### Scripts
Custom norns applications with:
- Main Lua file
- UI (screen, encoders, keys)
- Parameter system
- Optional libraries

### Mods
System-level extensions that:
- Run alongside scripts
- Hook into norns lifecycle
- Add global functionality
- Modify system behavior

### Engines
SuperCollider audio engines that:
- Provide synthesis capabilities
- Expose parameters to Lua
- Handle audio processing
- Integrate with norns scripts

## Current Status: Sparse First Version

This is a minimal viable version with:
- ✅ Core development principles
- ✅ Basic structure for scripts, mods, and engines
- ✅ Essential patterns and templates
- ✅ Reference to norns documentation

See [TASKS.md](./TASKS.md) for the roadmap to a more extensive version.

## Contributing

This is an early version! Contributions welcome:
- Additional pattern libraries
- More examples
- Common pitfall documentation
- Testing strategies
- Integration patterns (MIDI, Grid, Arc, etc.)

## Resources

- **Norns Documentation**: `../norns/doc/` (local) or https://monome.org/docs/norns/
- **Community**: https://llllllll.co/
- **Scripts**: https://norns.community/
- **Source**: https://github.com/monome/norns

## License

Same license as referenced norns materials.
