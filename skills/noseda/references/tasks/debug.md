# Debugging and testing on norns

Use the [modern definitions](../modern.md) to decide expected behavior, and the
[review checklist](review.md) for migration risks. Desktop is useful for
functional checks; hardware establishes audio timing, device behavior and feel.
N/D citations use the [audited baseline](../modern.md#evidence-and-scope).

## Discover the actual target

Ask for missing connection details and check what exists before deploying:

```bash
command -v norns-desktop
pgrep -af 'ws-wrapper.*5555'
getent hosts norns.local
ssh -o ConnectTimeout=10 -o BatchMode=yes we@<ip> 'cat ~/version.txt; systemctl list-units --no-pager "norns*"'
```

Record build/channel, hardware or desktop fork/backend, mods, component revision
and dependencies. Don't prescribe a beta upgrade as a generic debugging step.
The sidecar beta has a reported `io.popen` failure: source confirms substituted
`io.popen` cannot write/stream and waits for command completion. Test the exact
subprocess operation on that build; neither an upstream unit test nor a successful
stock-Lua run establishes beta compatibility. See
[target compatibility](../modern.md#target-compatibility-comes-first).

Use an IP if hostname resolution is the problem; distinguish resolution, SSH,
REPL and maiden failures. Current upstream image services include `norns-main`,
`norns-sclang` and `norns-jack`; older releases/forks differ. Inspect their
definitions instead of assuming service names or credentials from a version date.

Evidence: N `image/config/etc/systemd/system/norns-{main,sclang,jack}.service`,
`norns/main.cpp`, `matron/src/lua_shell.cc:1–5,231–261,286–301`.

## Matron REPL over websocket

The standard services expose Lua on 5555 and sclang on 5556 through ws-wrapper.
The client uses the `bus.sp.nanomsg.org` subprotocol, sending newline-terminated
Lua and receiving stdout. `scripts/nrepl.py` (relative to the skill directory)
needs the dependency in `scripts/requirements.txt` (`websocket-client`).

```bash
python3 <skill-dir>/scripts/nrepl.py --host <ip> --wait 25 'norns.script.load("code/<script>/<script>.lua")'
python3 <skill-dir>/scripts/nrepl.py --host <ip> 'print(params:get("clock_tempo"))'
python3 <skill-dir>/scripts/nrepl.py --host localhost "dofile('/abs/path/test.lua')"
```

Engine loading is asynchronous; wait for init completion rather than issuing
dependent tests immediately. For long tests, run a scoped clock coroutine in
matron and write its report under `norns.state.data`; fetch it after completion.
A disconnected client doesn't inherently cancel a started coroutine.

Evidence: N `maiden-repl/README.md:13–25`, `ws-wrapper/src/main.c:19–21,45–60,80–114`,
`image/config/etc/systemd/system/norns-main.service`, `norns-sclang.service`
(same directory), `lua/core/script.lua:230–247`, `lua/core/engine.lua:89–109`.

## Deployment and logs

Inspect the installed directory and local modifications before replacing code.
Use a new test directory/worktree or an explicitly agreed update location; keep
the user's scripts and saved data. Record exactly which revision is deployed.
Mods install at `dust/code/<mod>/lib/mod.lua`, then enable in SYSTEM > MODS and
restart. Changed SC classes need recompilation/restart; Lua-only changes can
normally be reloaded through `norns.script.load`.

```bash
journalctl -u norns-main -n 100 --no-pager
journalctl -u norns-sclang -n 100 --no-pager
journalctl -u norns-jack --since '10 min ago' --no-pager
```

Check the first relevant compile/load error, not only the last symptom. Duplicate
SC classes can prevent sclang startup before any script init hook runs. Save logs
with target/build/test conditions. For remote failures use bounded retries and
resumable result files; don't mistake interrupted transport for a code result.

Evidence: N `sc/norns-config.sc:12–16`, `lua/core/startup.lua:79–103`,
`lua/core/mods.lua:13–58`, `lua/core/menu/mods.lua:78–85`;
D `norns/engine-study-1.md:172–174`, `norns/mods.md:24–55`.

### Version-specific JACK/shared-memory failure

A previous hardware observation on shield build 260616: with logind `RemoveIPC`
enabled and no user linger, the last SSH logout could remove JACK shared-memory
resources, leaving running clients but preventing new connections. This is a
configuration/version-specific incident, not a universal norns/SSH rule.
Audited upstream now supplies `RemoveIPC=no` in
`N image/config/etc/systemd/logind.conf.d/10-norns-removeipc.conf`.

If logs show JACK connection failure while its service runs, inspect `/dev/shm`,
`jack_lsp`, and the actual logind configuration. Restart the installed audio
services coherently if necessary and authorized; don't restart JACK on every
deployment or change system configuration without identifying the condition.

## Desktop checks

A local `norns-desktop` launcher may manage maiden, sclang and an SDL norns
backend. Inspect that launcher's paths, ports, key mappings and restart behavior:
they are installation-specific, not a universal norns API. A known local setup
logs to `~/norns.log`, `~/sclang.log`, `~/maiden.log` and maps Alt+1/2/3 to keys,
Alt+q/w, a/s, z/x to encoders; verify before relying on those bindings.

Use a test dust tree when possible and include the engine in the SC class path
before compilation. Avoid starting a second instance on occupied ports or
restarting an active user session. Note enabled mods and MIDI vport names here
too. The inspected upstream SDL backend doesn't generate native refresh events;
a refresh-only script needs hardware or an appropriate backend test.

Evidence: N `matron/src/hardware/screen/sdl.cc:69–79`,
`matron/src/hardware/screen/ssd1322.cc:106–125`, `sc/norns-config.sc`.
Launcher behavior above is a local environment observation, not monome docs.

## Scoped testing and diagnostics

Prefer direct unit boundaries where available: call a step with deterministic
state, capture output, inspect its result. Plain Lua 5.3 can load suitable pure
libraries with `<norns>/lua/lib/?.lua` on `package.path`; stub host primitives
explicitly. Syntax-check with `luac5.3 -p file.lua`. The build uses Lua 5.3
(`N third-party/wscript`). These don't test matron bindings, audio or beta shell
substitutions.

When external instrumentation is necessary:

- A global callback's lexical upvalues can be inspected with Lua's
  `debug.getupvalue` and temporarily replaced with `debug.setupvalue`. This is
  diagnostic instrumentation, not production module architecture.
- Save originals and restore wrappers on success and failure. Vport methods
  are per-port fields: assigning nil deletes them. Params methods are inherited;
  preserve any existing instance override rather than assuming there is none.
- The global `engine` is a read-only proxy except its name; ordinary assignment
  cannot wrap its commands. Instrument the caller or capture output elsewhere.
- New script globals are reset on script load. Mutated system tables and cached
  modules are not isolated by that reset; a stored wrapper there can retain a
  dead script instance. Don't repeat the blanket claim that globals survive.

Evidence: N `lua/core/startup.lua:25,31`, `lua/core/script.lua:26–50`,
`lua/core/paramset.lua:85–103`, `lua/core/midi.lua:17–39`,
`lua/lib/tabutil.lua:218–251`. Lua debug-library usage is generic Lua, not a
norns-specific convention. See [MIDI captures](../patterns/midi.md) and
[performance metrics](optimize.md).

## Screen capture and input routing

`screen.export_screenshot('shot')` writes `norns.state.data .. 'shot.png'`.
Inspect that path and call after a completed draw/update. Capture the norns
frame rather than the whole desktop. Remove only test files you created.

```bash
python3 <skill-dir>/scripts/nrepl.py --host <ip> 'print(norns.state.data); screen.export_screenshot("shot")'
scp we@<ip>:dust/data/<script>/shot.png /tmp/
```

Calling `key()`/`enc()` directly tests script handlers. To diagnose actual
dispatch, note that play-mode wiring captures input handlers by value, while
menu transitions restore stored redraw/refresh callbacks. In a version-scoped
REPL harness, `_menu.key(3, 1)` and `norns.encoders.callback(2, 1)` reach the
currently routed handlers. These are **internal diagnostic entry points**,
not production script integration. Test press and release, and know whether
the menu is active. Prefer the shipped fileselect/textentry modal APIs over
manually replacing all input/screen internals.

Evidence: N `lua/core/screen.lua:397–399`, `lua/core/menu.lua:128–175`,
`lua/lib/fileselect.lua:38–81`, `lua/lib/textentry.lua:54–87`.

## Report checks honestly

### Recorded physical acceptance run

The repository's `acceptance/2026-10-15-pi3-260616/REPORT.md` records a Pi 3 B+
shield (PCB 200323), update marker 260616, modified core `4cbb17f`. Verbatim
skeletons ran; physical audio/controls and menu behavior were user-confirmed.
It is not an unmodified stable-image baseline.

That target reproduced a queued-resume race: cancelling a clock whose resume is
already queued can leave `clock.resume` calling `coroutine.resume(nil)` at
`lua/core/clock.lua:62`. Two sleeping coroutines with the same deadline, the
first cancelling the second, reproduced it 10/10 times without engine commands.
Capture thread IDs and queued/cancel ordering when investigating this error;
resource ownership assertions can pass before the queued error is dispatched.
Affected/fixed upstream release boundaries remain unverified.

After `Script.clear`, this target recreates three core clocks in
`clock.add_params` (crow output, MIDI output and external-tempo monitoring).
Distinguish their provenance from script-owned clocks rather than asserting
that `clock.threads` must be empty. Post-power-on connectivity was intermittent.
The user later recalled likely restarting norns first, which explains `NO SCRIPT`:
on this target, `_norns.restart` clears the script before saving clean state,
while `norns.shutdown` saves the active script before cleanup. Startup
`state.resume` reloads only a clean, nonempty, existing saved script. Thus a
restart followed by shutdown without selecting another script preserves the
empty selection. Direct SLEEP-from-script recall still needs a controlled device
check. Evidence: target `lua/core/{norns,script,state}.lua`. Fetch volatile
journals before power cycling.

### Reporting boundaries

State syntax/offline, host-instrumented, desktop-runtime and physical-device
checks separately. Include exact version/build for subprocess/sidecar failures.
After a refactor, check PSET/PMAP fixtures, first-note/transport behavior, notes
on stop/output change, menu/modal redraw and repeated load/cleanup. Hardware
CPU/audio/refresh validation remains necessary when those behaviors matter.
