# NoSEDA - Norns Script and Engine Development Assistant

An agent skill for developing monome norns scripts, mods, and engines with agentic AI.

## What is NoSEDA?

NoSEDA is a skill (`noseda`) in the [Agent Skills](https://agentskills.io) format, usable from Claude Code and opencode. It gives the agent norns development patterns and best practices. The agent loads it when you work on norns code, detects whether the project is a script, mod, or engine, and reads only the guides that apply.

## File Structure

```
├── AGENTS.md                        # Notes for agents editing this repository
├── CLAUDE.md                        # Redirect to AGENTS.md
├── README.md                        # This file
├── TASKS.md                         # Roadmap for extensive version
└── skills/
    └── noseda/
        ├── SKILL.md                 # Entry point: core principles, what to read when
        ├── references/
        │   ├── components/
        │   │   ├── script.md        # Script development guide
        │   │   ├── mod.md           # Mod development guide
        │   │   └── engine.md        # Engine development guide
        │   ├── patterns/
        │   │   ├── timing.md        # clock loops, transport, tick budget
        │   │   ├── midi.md          # note-off bookkeeping, testing MIDI output
        │   │   └── params.md        # id collisions, groups, optional includes
        │   └── tasks/
        │       ├── debug.md         # testing on a norns over wifi and on desktop norns
        │       └── optimize.md      # measuring performance, xruns, fair comparisons
        └── scripts/
            └── nrepl.py             # Send Lua to a norns REPL over websocket
```

## Usage

### Install

Clone the repository anywhere, then link the skill directory into a skills folder. The link must be named `noseda`.

```bash
git clone https://github.com/vehka/noseda.git ~/src/noseda
mkdir -p ~/.claude/skills
ln -s ~/src/noseda/skills/noseda ~/.claude/skills/noseda
```

`~/.claude/skills/` is read by both Claude Code and opencode, so this one link covers both, in every project. Other locations:

| Location | Read by | Scope |
|---|---|---|
| `~/.claude/skills/noseda` | Claude Code, opencode | all projects |
| `~/.config/opencode/skills/noseda` | opencode | all projects |
| `<project>/.claude/skills/noseda` | Claude Code, opencode | one project |
| `<project>/.opencode/skills/noseda` | opencode | one project |

Copy the directory instead of linking it if you want to commit the skill into a norns project.

`scripts/nrepl.py` needs `pip install websocket-client`.

### Norns core repository (optional but recommended)

The guides point at the norns source for reference. Clone it next to your norns project:

```bash
git clone https://github.com/monome/norns.git
```

```
.
├── norns/              # norns core (reference)
└── mynornsproject/     # Your script, mod or engine
```

### Use

Start Claude Code or opencode in your norns project and ask for what you need. The agent loads the skill when the request is about norns. In Claude Code you can also call it directly with `/noseda`.

### What Gets Loaded

`SKILL.md` (core principles) is loaded with the skill. From there the agent reads:

- **Script project**: `components/script.md`
- **Mod project** (has `lib/mod.lua`): `components/mod.md`
- **Engine project** (has an `Engine_*.sc` file): `components/engine.md`
- **Patterns** (timing, MIDI, params) when the code uses them
- **Tasks** for the kind of work: `debug.md` for running and testing on a
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
