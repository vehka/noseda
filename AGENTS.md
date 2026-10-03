# NoSEDA

This repository holds an agent skill, `noseda`, for developing monome norns
scripts, mods and engines. It is used from Claude Code and opencode; see
[README.md](./README.md) for installation.

## Layout

```
skills/noseda/
├── SKILL.md              # entry point: frontmatter, core principles, what to read when
├── references/
│   ├── components/       # script.md, mod.md, engine.md
│   ├── patterns/         # timing.md, midi.md, params.md
│   └── tasks/            # debug.md, optimize.md
└── scripts/
    └── nrepl.py          # send Lua to a norns REPL over websocket
```

## Editing the skill

- The `name` in the `SKILL.md` frontmatter must equal the directory name
  (`noseda`); opencode rejects the skill otherwise.
- The frontmatter `description` decides when agents load the skill. Keep it
  about what the skill does and when to use it, under 1024 characters.
- `SKILL.md` is always loaded once the skill triggers, so keep it short and put
  detail in `references/`. When adding a reference file, add a row for it to
  the tables in `SKILL.md`, or agents won't find it.
- Paths inside the skill are relative to the skill directory. Don't rely on
  `${CLAUDE_SKILL_DIR}` or other tool-specific variables.
- [TASKS.md](./TASKS.md) is the roadmap.
