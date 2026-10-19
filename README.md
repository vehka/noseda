# NoSEDA — Norns Script and Engine Development Assistant

An [Agent Skills](https://agentskills.io) skill for writing, reviewing,
refactoring, debugging and optimizing monome norns scripts, mods and
SuperCollider engines. It works with Claude Code and opencode.

## What it teaches

[Modern norns components](skills/noseda/references/modern.md) defines the common
standard for the current stable release (260102, norns `v2.9.4`), verified
against pinned source and monome docs. It distinguishes
platform contracts, conventions, architectural recommendations, undocumented
interfaces and optional ecosystem dependencies.

- Params-first settings, stable IDs, PSET/PMAP compatibility and sidecar state.
- Runtime data under `norns.state.data`, generated audio under `_path.audio`.
- Beat-aware clocks and lattice; supported seconds-based metro usage.
- Dirty rendering, screen/modal ownership, and the source-only `refresh()` hook.
- Norns-specific global lifetime, module encapsulation and protected system names.
- Real mod hooks/menu APIs, resource ownership and engine parameter libraries.
- Legacy reviews reporting **idiom → replacement → risk of changing it**.

Modern does not mean latest beta. A separate
[beta compatibility](skills/noseda/references/tasks/beta-compat.md) guide covers
making components work on the 3.x beta (for example its `io.popen` changes); it
loads only when asked for or when a failure is beta-specific.

## Install

Clone anywhere, then link the skill directory into a skills folder. The link
must be named `noseda`, matching the skill's frontmatter name.

```bash
git clone https://github.com/vehka/noseda.git ~/src/noseda
mkdir -p ~/.claude/skills
ln -s ~/src/noseda/skills/noseda ~/.claude/skills/noseda
```

`~/.claude/skills/` is read by both Claude Code and opencode. Other locations:

| Location | Read by | Scope |
|---|---|---|
| `~/.claude/skills/noseda` | Claude Code, opencode | All projects |
| `~/.config/opencode/skills/noseda` | opencode | All projects |
| `<project>/.claude/skills/noseda` | Claude Code, opencode | One project |
| `<project>/.opencode/skills/noseda` | opencode | One project |

Copy the directory instead of linking if committing the skill into a project.
For the optional REPL client, install `websocket-client` from
`skills/noseda/scripts/requirements.txt` in your Python environment.

## Use

Start the agent in your norns project and ask for the work. The skill detects
script/mod/engine components, applies their modern definition, and loads only
relevant guides. Projects can contain multiple component types. In Claude Code
you can also invoke `/noseda` directly.

Examples:

> Write a small norns sequencer with PARAMS controls and explicit transport behavior.

> Review this legacy sampler. For each finding give the idiom, replacement and
> risk to existing sessions or musical behavior.

> Refactor this mod to use the actual hook/menu interfaces and coexist with scripts.

> Build a synthesis engine with a reusable Lua parameter library, and test its lifecycle.

> Compare timing and xruns before and after this change on my norns build.

### Source checkouts

Local norns and monome/docs checkouts make verification easier:

```bash
git clone https://github.com/monome/norns.git
git clone https://github.com/monome/docs.git monome-docs
```

Tell the agent where they are and which release the component supports; check
out the matching tag (`git -C norns checkout v2.9.4` for stable).
Core paths are `lua/core/`, `lua/lib/`, `matron/src/`, and `sc/core/`; public
documentation source is under `monome-docs/norns/`. The norns `doc/` directory
contains generated API material. Upstream HEAD is the 3.x beta line, not stable.

## What gets loaded

`SKILL.md` is the lean entry point. `references/modern.md` supplies shared rules
and the relevant component definition. Then the agent follows this routing:

| Need | Guide |
|---|---|
| Script / mod / engine construction | `references/components/{script,mod,engine}.md` |
| Params, state, timing, UI or output detail | Relevant `references/patterns/` file |
| Review/refactor | `references/tasks/review.md` |
| Running and debugging | `references/tasks/debug.md` |
| Performance measurement | `references/tasks/optimize.md` |
| A specifically scoped implementation to study | `references/exemplars.md` |
| 3.x beta support, beta-only failures, core work | `references/tasks/beta-compat.md` |

Each component guide includes a minimal runnable skeleton. Running it on the
target device is a separate check from source verification and syntax parsing;
report those checks distinctly.

## Repository layout

```text
AGENTS.md                     # Instructions for agents editing this repository
CLAUDE.md                     # Redirect to AGENTS.md
README.md
TASKS.md                      # Completed baseline and focused roadmap
skills/noseda/
├── SKILL.md                  # Detection, modern standard, selective routing
├── references/
│   ├── modern.md             # Stable target, definitions, source baseline
│   ├── exemplars.md          # What to learn from each audited project
│   ├── components/
│   │   ├── script.md
│   │   ├── mod.md
│   │   └── engine.md
│   ├── patterns/
│   │   ├── params.md
│   │   ├── state.md
│   │   ├── timing.md
│   │   ├── ui.md
│   │   └── midi.md
│   └── tasks/
│       ├── review.md
│       ├── debug.md
│       ├── optimize.md
│       └── beta-compat.md     # Opt-in: 3.x beta differences
└── scripts/
    ├── nrepl.py               # Lua REPL websocket client
    └── requirements.txt
```

## Development status

The source-verified modern baseline and review workflow are implemented.
[TASKS.md](TASKS.md) separates this foundation from advanced UI, hardware,
session-management and DSP work. New guidance needs evidence and a route from
`SKILL.md`; examples need checks appropriate to their behavior and target.

Resources: [monome docs](https://monome.org/docs/norns/),
[norns source](https://github.com/monome/norns),
[norns community](https://norns.community/), [lines](https://llllllll.co/).

## Contributing and license

Contributions welcome: focused patterns, source corrections, hardware results
and realistic review/refactor examples. Preserve the distinction between an API
fact and a recommendation. Record firmware/build and dependencies with results.

Same license as referenced norns materials.
