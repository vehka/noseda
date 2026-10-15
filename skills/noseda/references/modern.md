# Modern norns components

## Contents

- [Evidence and scope](#evidence-and-scope)
- [Shared rules](#shared-rules)
- [Script definition](#script-definition)
- [Mod definition](#mod-definition)
- [Engine definition](#engine-definition)
- [Verification gaps and disagreements](#verification-gaps-and-disagreements)

## Evidence and scope

A modern component uses current norns interfaces, integrates with the platform,
owns its resources, and makes its musical and persistence policies explicit.
Age, popularity, locals everywhere, and replacing every metro are not tests of
modernity. Preserve intentional behavior when reviewing older instruments.

Audited **2026-10-15**, against these official snapshots:

- **N**: [monome/norns at 6302a0d4dcb85ab3b701a4d7268863092b693caf](https://github.com/monome/norns/tree/6302a0d4dcb85ab3b701a4d7268863092b693caf)
  (2026-10-11).
- **D**: [monome/docs at de746029ef57244036df2a206e5b894a29b5e0f6](https://github.com/monome/docs/tree/de746029ef57244036df2a206e5b894a29b5e0f6)
  (2026-10-01).

`N lua/core/script.lua` means that path in the pinned norns tree; `D norns/…`
means a path in the pinned docs tree. Citations describe those revisions, not
every installed release. Inspect the target version before relying on them.
The audited `N releases.txt` lists stable `260102` and beta `260819`; upstream
HEAD is not itself a minimum firmware version.

### Target compatibility comes first

Modern idioms should work on the intended supported release; adopting a beta
is not a modernization step. Record version/build, release channel, backend and
enabled mods when testing. Do not require a newer release without a concrete
API need and evidence that the component works there.

**User-reported compatibility issue (2026-10-15):** the latest beta with sidecar
has serious bugs, including non-working `io.popen`. The exact affected builds,
failure mechanism and fixed release were not established in this audit. Do not
present subprocess use on that beta as verified, or assume a core utility that
calls `io.popen` is unaffected. Reproduce on the target build before relying on
it. The component skeletons do not directly use `io.popen`. Source availability
of sidecar or a shell API does not prove it is a working drop-in replacement.

**Source-corroborated limitations:** N `matron/src/lua_shell.cc:1–5,231–261,286–301`
replaces Lua's `os.execute`/`io.popen`, explicitly rejects popen write mode, and
returns buffered output from a finished command instead of a live process. Its
FIXME states that reads don't stream and an unbounded producer never returns.
N `tests/matron/lua_shell/test_lua_shell.cpp:381–388` tests write-mode refusal.
These explain specific incompatibilities without establishing every reported
failure or a release boundary. An offline stock-Lua test doesn't exercise them.

Use these evidence classes:

- **Contract**: implementation behavior, verified in source.
- **Convention**: documented platform usage, not necessarily enforced.
- **Recommendation**: this skill's architectural preference, with exceptions.
- **Undocumented**: implemented but not described in the inspected public docs.
- **Ecosystem**: an external dependency, not a core API.

Call a pattern modern only when current core/docs support it, or when at least
two maintained scripts demonstrate it. Record the paths and evidence of
maintenance for that second route; a last-commit date alone does not establish
maintenance. [Exemplars](exemplars.md) assign narrow purposes, not blanket style
endorsements. Where docs and implementation disagree, explain the discrepancy.

## Shared rules

### Scope and dependencies

**Contract:** norns redirects new script globals through `_G`'s metatable into
a state table replaced by `Script.clear()`. This does not isolate overwrites of
existing system globals, mutations of shared library tables, or cached modules.
It is script-lifecycle isolation, not a security sandbox.

**Convention/recommendation:** expose script callbacks globally. Small scripts
may use script-global state. Prefer lexical locals for encapsulation and
explicit dependencies as complexity grows; reusable `lib/` modules ordinarily
return local tables. There is no norns requirement to prefix private helpers
with `_`, or to reject all globals.

Do not shadow/replace system bindings with project state: `util`, `tab`,
`params`, `clock`, `metro`, `screen`, `grid`, `midi`, `arc`, `crow`, `softcut`,
`engine`, `audio`, `poll`, `norns`, `include`, `_menu`, `_norns`, `_path`, etc.
This includes lexical aliases with misleading meanings, not just global writes.

Load shipped libraries with `require 'musicutil'`, `'lattice'`, `'sequins'`,
`'lfo'`, `'pattern_time'`, `'reflection'`, `'ui'`, `'textentry'`, `'fileselect'`.
Core objects such as `params`, `clock`, `screen` and `controlspec` already exist.
For script helpers use `local helper = include('lib/helper')`; `include` runs
the file each time, whereas `require` caches modules. For mod helpers use
project-qualified `require 'mymod/lib/helper'`, independent of the active script.

**Evidence:** N `lua/core/script.lua:26–50`, `lua/core/startup.lua:3–35,51–65`,
`lua/core/config.lua:6–16`, `lua/lib/`; D `norns/reference.md` (libraries),
`norns/mods.md:145–167` (cached mod interface).

### Use platform facilities and respect shared ownership

Prefer PARAMS, PSETs, PMAP, shipped UI helpers and libraries when they fit.
Use the shipped core implementation rather than vendoring a modified copy as
a default. These are maintainability recommendations, not loader restrictions.
Avoid production dependencies on `_menu`/`_norns` internals; a leading underscore
alone does not decide documentation status: `_path` is documented, as is
`_menu.rebuild_params()` for dynamic parameter visibility.

Separate assignable extension callbacks from implementation replacement.
Scripts may define `midi.add`, `grid.add` and `clock.transport.*`; core resets
these. Wrapping shared implementations or replacing a system param action
requires preserving existing behavior and restoring the change when its owner
ends. Mods must compose with scripts and other mods rather than claim ownership
of every callback slot.

**Evidence:** N `lua/core/midi.lua:74–84,197–209`,
`lua/core/grid.lua:73–85,145–163`, `lua/core/clock.lua:85–95,129–145,228–238`;
D `norns/reference/parameters.md:24–73,267–288`, `norns/reference.md:205–222`.

## Script definition

### Layout, header and startup

Recommend `dust/code/<name>/<name>.lua`, helpers under `lib/`, and a README
explaining controls/dependencies. Matching the main filename and directory is
a convention; core supports multiple script entry points in a project.
A contiguous opening comment block becomes the preview metadata. Include name,
short description, version/author, a discussion/docs URL, and controls; these
are human-facing conventions, not parsed mandatory fields.

Set `engine.name` before initialization if using an engine. Core loads the
engine and registers its commands before calling script `init()`. Declare
`norns.version.required = YYMMDD` for a verified minimum update when needed.
The check follows top-level execution: defer version-dependent calls until
`init()` or guard top-level loading appropriately.

`init`, `key`, `enc`, `redraw`, `cleanup`, and `refresh` have platform defaults;
omission is not itself a load error. In particular, omitted `redraw` leaves the
blank default (internally marked `norns.script.nointerface`), and omitted
`cleanup` uses a no-op. Define callbacks at script scope: the loader captures
`redraw`/`refresh` before running `init()`.

**Evidence:** N `lua/core/script.lua:52–63,97–98,157–273`,
`lua/core/engine.lua:89–109`, `lua/core/menu.lua:13–18,157–175`;
D `norns/reference.md:94–175`.

### Params-first control and persistence

Use params as the source of truth for user-facing settings that should be
editable, mappable or recalled. Use stable collision-free IDs, appropriate
types, controlspec/taper ranges, units/formatters, separators and sized groups.
Groups cannot nest. Namespace new reusable IDs; preserve existing IDs and
option meanings during refactors, or migrate their saved representation.
Custom encoders/keys update params; actions drive sound and derived state.

Once resources, parameters and actions exist, apply initial values with
`params:bang()`, normally near the end of `init()`. It applies actions, not
saving. It skips trigger params and inactive trigger-behavior binaries.
Use a deliberate startup PSET policy: `params:read(slot, true)` plus one bang,
or `params:default()` (read then bang), accounting for sidecar action ordering.
An ordinary non-silent `params:read()` already invokes changed-value actions.

Not every state item belongs in params: steps, recordings and transient input
state can remain tables. Persist PSET-associated extra state with
`params.action_write/read/delete` and sidecars under `norns.state.data`.
Define defaults and migrations for absent/older data. Runtime PSETs and data
belong in this directory, normally `dust/data/<name>/`; recorded/generated audio
belongs under `_path.audio`. Don't treat `norns.state` as an arbitrary persistent
application-state table: `norns.state.data` is a **directory path**.

Bundled default `.pset` files may live in code-side `data/`; core copies them
when first creating the runtime data directory. That exception is for shipping
defaults, not writing user saves back into the code tree.

**Evidence:** N `lua/core/paramset.lua:111–315,357–425,498–610`,
`lua/core/params/control.lua:68–120`, `lua/core/script.lua:186–211`,
`lua/core/config.lua:25–29`, `lua/core/state.lua:107–170`;
D `norns/reference/parameters.md:154–404`.

### Timing, sequencing and rendering

Use `clock.sync()` for beat synchronization and `clock.sleep()` for coroutine
delays. Keep handles for work stopped/replaced during the script's lifetime;
prevent duplicate transport starts and define continue/restart/quantization.
`clock.run` resumes immediately until its first yield. `clock.sync(1)` is one
quarter-note beat; `clock.sync(1/4)` is a sixteenth note in 4/4.

Use lattice for coordinated divisions, swing and execution order when helpful;
use its current `new_sprocket`, not deprecated `new_pattern`. Sequins produces
values, not timing. A simple clock loop is still modern. `pattern_time` records
seconds-based events; `reflection` provides clocked event recording/playback.
**Metro is supported**, including UI timers and independent seconds-based work.
Do not mechanically convert it to clock or confuse it with legacy BeatClock.

For frequent changes/animation, mark screen/grid dirty and redraw at a chosen
cadence; 15–30 fps is a useful default, not a maximum. Direct redraw from an
occasional event callback is supported. Ordinary Lua MIDI, poll, softcut and
clock callbacks run through matron's control event loop, not a Lua DSP callback.
Keep rendering out of high-rate musical paths as a workload recommendation.

**Undocumented:** global `refresh()` is called by
`matron/src/weaver.cc::w_handle_screen_refresh` from hardware display events
nominally every 16,666,666 ns (~60 Hz). It is separate from `redraw()` and
`screen.update()`, and managed during script/menu transitions. Dispatch latency
can vary. The inspected SDL backend has no equivalent event producer. Don't
make it the portable default; consider modal UI ownership too.

**Evidence:** N `lua/core/clock.lua:19–95`, `lua/lib/lattice.lua:18–163`,
`lua/lib/sequins.lua`, `lua/lib/pattern_time.lua`, `lua/lib/reflection.lua`,
`matron/src/events.cc:181–353`, `matron/src/weaver.cc:2916–2919`,
`matron/src/hardware/screen/ssd1322.cc:106–125`,
`matron/src/hardware/screen/sdl.cc:69–79`;
D `norns/clocks.md`, `norns/grid-recipes.md:49–84`,
`norns/reference/metro.md:100–110`, `norns/study-2.md:163–182`.

### Output and teardown

Choose direct engine/softcut, MIDI, crow or optional nb voices for the musical
task. nb is an external voice/player abstraction, not a required core output
path; declare its installation and backend dependencies. Track external note
ownership and end sounding notes/gates on stop, output changes and cleanup.

During script clearing core requests engine release, attempts Lua `cleanup()`,
calls mod post-cleanup hooks, then resets script globals, devices, script metros,
clocks, polls, softcut, params and other platform state. Explicitly stop owned
work when useful, and clean up things core cannot: external notes/processes,
files, and shared-table modifications. Make cleanup safe after partial init.
Do not rely on sending engine commands in Lua cleanup: release was already
requested. SC resources belong in engine `free`. SLEEP calls Lua cleanup without
the entire `Script.clear()` sequence, another reason for explicit ownership.

**Evidence:** N `lua/core/script.lua:11–124`, `lua/core/norns.lua:195–205`,
`lua/core/midi.lua:101–111`, `lua/core/crow/public.lua`,
`sc/core/CroneEngine.sc:42–55`; ecosystem sources in [exemplars](exemplars.md).

## Mod definition

A mod has `dust/code/<project>/lib/mod.lua`, loaded with `require` when enabled
at startup. Enable/disable changes apply on restart, not immediate unloading.
Module locals and returned APIs can persist across script changes; script
globals and facilities reset separately. Use project-qualified helper imports.

Register uniquely named callbacks with `mods.hook.register(which, name, fn)`
from `require 'core/mods'`. Source also provides `mods.hook.deregister` to remove
one; that helper is not described in the inspected public mod guide. Callback
names sort alphabetically within a hook; don't infer mod load order from that.

| Hook | Source-verified point |
|---|---|
| `script_pre_init` | After script top level, before engine loading and `init` |
| `script_post_init` | After successful script `init` |
| `script_post_cleanup` | After Lua cleanup, before remaining script resets; engine teardown need not have completed |
| `system_post_startup` | `_post_startup` after startup/device scanning/pending-event processing; not a guaranteed pre-script barrier |
| `system_pre_shutdown` | At the start of SLEEP and RESTART paths |
| `audio_post_restore_default_routing` | After default audio connections are restored |

Optional settings pages use `mods.menu.register(name, menu_table)` with `init`,
`deinit`, `key`, `enc`, `redraw` callbacks, and `mods.menu.redraw/exit` helpers.
Capture `mods.this_name` while loading if needed; the loader clears it afterward.
It is not a schema of parameter descriptors.

Modern genres include utility/system mods, nb voice-provider mods and
engine-providing mods. Those are ecosystem packaging categories. Declare any
specific script contract; otherwise work across scripts and coexist with mods.
Restore shared changes and account for script resets cancelling clocks and
clearing callbacks/params even while the mod's module locals survive. Starting
services in `script_post_cleanup` can put them just before those resets.

**Evidence:** N `lua/core/mods.lua:13–69,81–88,111–140`,
`lua/core/hook.lua:13–42`, `lua/core/script.lua:11–124,145–149,230–247`,
`lua/core/norns.lua:195–205,247–268`, `lua/core/audio.lua:478–494`,
`lua/core/menu.lua:191–205`, `matron/src/main.cc:124–140`;
D `norns/mods.md:24–55,104–167`.

## Engine definition

Use a unique `Engine_<Name>` class extending `CroneEngine`, conventionally
distributed in `lib/Engine_<Name>.sc`. Crone discovers compiled subclasses by
class name; a matching filename is the distribution convention, not a filename
check. SC includes dust classes and needs recompilation after class changes.

Allocate resources in `alloc` and release owned resources in `free`. The inherited
constructor is sufficient. `alloc` runs in a Routine; finish asynchronous setup
before returning, using `context.server.sync` when subsequent work depends on
server operations such as sending a SynthDef. Both `.send(context.server)` and
`.add` appear in supported examples; `.add` is not mandatory.

Expose commands with `addCommand(name, format, fn)`; formats include `i`, `f`,
`s`, and `""` for no payload. The handler gets a raw OSC message: address at
`msg[0]`, first argument at `msg[1]`. Document units/ranges/voice behavior.
`addPoll(name, fn, periodic=true)` is optional feedback, not a required method
call. Base teardown removes commands and registered polls before calling `free`.

Use `context.server`, `context.xg` or owned child groups, and final stereo output
to `context.out_b`. Free owned synths, groups, buffers, buses, tasks/responders;
do not free the shared context's groups/buses. Namespace classes, SynthDefs and
custom poll names. Explicitly freed persistent synths are valid; per-note synths
need a bounded voice lifetime, often a self-freeing envelope. Bound polyphony,
test worst-case load on norns hardware, and retain headroom for the host script.
There is no verified universal CPU percentage suitable for every instrument.

For reusable controls, provide `lib/<name>_engine.lua` returning specs and an
`add_params()` function whose actions call engine commands. Let the host decide
when to load PSETs and bang. The documented engine study and passersby/Molly
demonstrate this separation. Consider an nb voice-provider mod before choosing
script-owned packaging if interchangeable note playback is the intended API.

**Evidence:** N `sc/core/Crone.sc:86–129,168–180`,
`sc/core/CroneEngine.sc:15–77`, `sc/core/CroneAudioContext.sc:33–46`,
`sc/core/CronePoll.sc:117–137`, `sc/norns-config.sc:12–16`,
`sc/engines/Engine_SimplePassThru.sc:16–50`, `sc/engines/Engine_TestSine.sc`,
`lua/core/engine.lua:44–73,89–129`, `matron/src/weaver.cc:1962–2025`;
D `norns/reference/engine.md:45–51`, `norns/engine-study-1.md:384–456,510–520`,
`norns/reference/poll.md:104–122`.

## Verification gaps and disagreements

- Sidecar popen write/streaming incompatibilities are verified in source; the
  broader beta failure report was not reproduced here. Exact release boundaries
  and a reliable workaround remain unverified. HEAD inspection is not beta
  runtime validation.
- `refresh()` is source-supported and used by plasma, but not documented as a
  public script callback in inspected docs. Its availability on other backends
  and exact introduction release need separate verification.
- D `norns/mods.md` lists five hooks, omitting the routing hook in N
  `lua/core/hook.lua`. Its startup wording is stronger than current call sites.
- D `norns/study-3.md:857` says PSET reading doesn't run actions; N
  `lua/core/paramset.lua:527–574` does unless silent (and value setters may skip
  unchanged values). Follow implementation and the current parameter reference.
- Lattice documentation lists an enabled default of true; source initializes
  false. Explicitly start it. LFO docs describe a depth default of 1, while N
  `lua/lib/lfo.lua:69–75` initializes 0; specify depth.
- Current consecutive syncs advance from stored scheduled beats, allowing late
  catch-up: N `matron/src/clocks/clock_scheduler.cc:159–184`, tested in
  `tests/matron/clocks/clock_scheduler/test_clock_scheduler.cpp:223–260`.
  Don't apply older “always skips missed ticks” observations to all firmware.
- Community example audit establishes particular code patterns, not ongoing
  maintenance or hardware compatibility. Minimum firmware numbers require
  release-history evidence; don't invent them from a checkout date.
- Skeleton syntax/behavior checks do not establish Pi timing, actual audio
  quality, physical-device behavior or `refresh()` cadence. Report these limits
  with the checks performed; see [debugging](tasks/debug.md).
