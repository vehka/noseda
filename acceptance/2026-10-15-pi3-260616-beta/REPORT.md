# Pi 3 shield acceptance run — 2026-10-15

> **Beta target.** Update 260616 is norns v3.0.1, a 3.x beta, and the core was
> locally modified. These results are beta evidence, not the stable (260102,
> v2.9.4) baseline. Directory renamed from `2026-10-15-pi3-260616` on
> 2026-10-19; paths inside `evidence/` record the original name.

## Verdict

**Target-specific acceptance completed with a reproducible clock-cancellation
failure; direct SLEEP-from-script recall remains untested. The unmodified
stable-image baseline in `TASKS.md` remains open.** All five skeleton files
installed verbatim and ran without compatibility edits. Script/engine sound, physical controls,
screen/menu behavior, persistence, isolated mod operation and engine teardown
worked in the checks below. This is not an unconditional green result.

## Target and conditions

| Item | Recorded value |
|---|---|
| Device | `10.0.0.138`, hostname `norns`, platform 3 / shield |
| Hardware | Raspberry Pi 3 Model B Plus Rev 1.3; shield PCB **200323**, confirmed by user |
| Update marker | `~/version.txt`: **260616** |
| Core checkout / running binary | `4cbb17fd27096d6632fb51cb3c1bcf5dcbbd1f29`; startup binary reports `4cbb17f` |
| Core condition | Locally modified Bluetooth/MIDI, startup, menu and weaver code; custom commit history. Original image identity/release channel is unverified. |
| OS | Raspbian 11, Linux `5.10.92-18-g458e2253667a`, armv7l |
| Audio | JACK realtime priority 95, 48 kHz, 128-frame periods × 3, ALSA `hw:sndrpimonome`, 16-bit; SC `3.13.0-dev` |
| Component revision | NoSEDA **89230771b7527a98fe247ae3e7db125b47ca25bf** |
| Connected devices | USB hubs/Ethernet only in `lsusb`; virtual MIDI, plus fluidsynth before mods were disabled. No physical MIDI controller, Grid, Arc or HID detected. Saved vport names are not connected devices. Analog cabling was not inventoried. |
| Initial state | `speech/speech.lua`, engine None, menu active, tempo 90 |
| Mod isolation | All eight original Lua mods disabled and process restarted; both enabled/loaded lists verified empty. Only `modern_counter` enabled during mod tests. |
| Other installed code | Existing dust SC classes/extensions still compiled; startup reports four method overrides. Disabling Lua mods does not remove compiled extensions. |
| Mixer | Original mixer retained, including enabled reverb and disabled compressor; original settings in `evidence/original-system.state` |
| Thermal/config | Initial `get_throttled=0x0`; after power-on `0x80000` (historical soft-temperature-limit flag), later temperature 59.61 °C. Thermal state was not sampled during every measurement. `RemoveIPC=no` was already configured. |

Full discovery is in [inventory.txt](evidence/inventory.txt). The locally modified
checkout and installed extensions exclude this device from the requested **stock
stable software** baseline even though it has the requested Pi/shield hardware.

## Results

“Device” means code executed in the physical shield's actual matron/crone runtime.
“Human” means the user explicitly confirmed a hands-on check during this session.

| Check | Result and evidence |
|---|---|
| Verbatim installation | **PASS.** `modern_steps.lua`, `modern_counter/lib/mod.lua`, and all three `modern_tone` files match the extracted Markdown blocks byte-for-byte. SHA-256 hashes in [manifest.json](evidence/manifest.json); remote hashes checked again at the end. No skeleton edits required. |
| Script inputs/transport | **PASS, with platform error below.** Routed K2/K3 and E2/E3, release events, parameter actions, 12 rapid start/start/stop/stop cycles per run, reset while running, double cleanup. Duplicate starts retained one sequence handle. User confirmed audible pattern, encoders, reset, stop/tail and menu while playing. |
| PARAMS/PSET | **PASS.** Numeric-slot read/write, action-driven root/amp, silent read followed by one bang, defaults after reload. Actual PARAMS PSET menu save/name/recall/delete also exercised with routed events; `pset-last.txt` and runtime data paths checked. |
| Sidecar fragment | **PASS.** Verbatim fragment with diagnostic getters/setters appended; roundtrip, missing/corrupt/schema-0 fallback, delete of only owned sidecar and PSET. It was exercised in the script host; the skeleton itself does not include a sidecar. |
| PMAP | **PASS for injected CC; physical controller untested.** PMAP save/clear/read; core `norns.menu_midi_event` receives CC21 on port/channel 1, values 0/127, producing roots 24/84. |
| Script dirty rendering | **PASS.** Script renderer not called while PARAMS owned the screen; return forced a current frame. User confirmed menu legibility while playing. Idle generated zero periodic updates after initial settling. |
| Native refresh/modal probe | **PASS for hardware delivery and explicit guard.** ~59.7 Hz in play, zero script refresh events in menu, resumed afterward. Refresh continued during both textentry and fileselect. Guarded dialogs remained visible in captured frames. Accept/cancel callbacks returned `accepted`, nil, and `"cancel"` respectively. |
| Engine compilation/commands | **PASS.** Discovered alongside installed engines after restart; three commands ready before host init. Routed encoders and PSET actions work. Server control reads verify clamps: Hz 40/4000, amp 0/0.5, gate 0/1. 24 rapid gate cycles. |
| Engine sound | **PASS.** Captured actual stereo engine bus: 440 Hz, RMS 0.141421/channel, peak 0.200000, identical channels at amp 0.2; zero after release. User confirmed clean tone, K3 hold/release and E2/E3 pitch/loudness/display. PolyPerc also had nonzero stereo output playing and zero after its tail. These are digital bus captures plus human listening, not analog calibration. |
| Engine switching/teardown | **PASS.** Three rounds of tone → tone reload while sounding → PolyPerc playing → clear. Tone consistently 9 synths / 15 groups / 54 UGens; clear consistently 8 / 15 / 46. No accumulated tone synths observed. Buffers/tasks were not independently leak-counted; the example allocates no such resources. |
| Partial Lua initialization | **PASS recovery.** Separate fault fixtures append an intentional top-level failure or an error after the original init. Both clear safely and recover to a normal tone host; failed init does not increment the mod count. SC alloc-failure injection was not performed. |
| Cleanup clock accounting | **PASS after correcting harness expectation.** Core recreates three system clocks after clear (`clock.lua:331,344,364`); inspection distinguishes those from script-owned work. No script clocks remained. Three earlier failed assertions expecting zero core clocks are retained as harness errors, not component leaks. |
| Isolated mod | **PASS.** Only example mod loaded; optional menu entry, E3 logging toggle, K2 return, cached count across unrelated `awake` and tone hosts, reruns and no-script state. Count progressed 1→2→3→4, and failed initialization did not increment it. User confirmed count 4/toggle/back physically. |
| Disable/restart | **PASS.** Disable changed enabled state while module stayed loaded; real `_norns.restart()` then removed it. Original eight mods restored afterward. |
| SLEEP / power-on | **USER-CONFIRMED shutdown and power-on; direct SLEEP-from-script recall untested.** User subsequently recalled likely restarting norns before the power cycle. Persisted observer saw `system_pre_shutdown` at count 4, then `script_post_cleanup` ~2 ms later, matching RESTART. After power-on only the example mod was loaded, count was 0, and norns showed `NO SCRIPT`. Both the reset session counter and empty script are expected after RESTART; they do not establish a shutdown/resume failure. Previous-boot journal was volatile and unavailable. |
| Network recovery | **RECOVERED, intermittent.** After power-on SSH/REPL initially failed with no-route/banner timeout despite the displayed address remaining `10.0.0.138`. Both later worked; evidence copied successfully. Cause unestablished. |

## Reproducible platform failure: cancelling an already queued clock resume

The script and ordinary `awake` loading produced:

```text
lua: /home/we/norns/lua/core/clock.lua:62:
  bad argument #1 to 'resume' (thread expected)
```

A minimal core-only reproducer, with no script engine commands, schedules two
sleeping coroutines at approximately the same deadline and lets the first cancel
the second. The scheduler still dispatches the second's queued resume, after
`clock.cancel` removed its entry from `clock.threads`. Scoped instrumentation
observed **10 stale IDs in 10 attempts**. The matron process continued running.

Reproduce on this target after installing the harness:

```bash
python run.py lua 'norns.script.clear()'
python run.py --wait 3 lua 'dofile(_path.code.."noseda_acceptance/checks.lua").cancel_race()'
```

The diagnostic's `PASS` means it completed recording the observation; it does
**not** mean cancellation behaved correctly. See `core-only-cancel-race` in
[results.jsonl](evidence/results.jsonl) and the corresponding command output in
[commands.jsonl](evidence/commands.jsonl). Exact affected/fixed upstream releases
are not established by this modified target. No core fix was installed.

Other observed messages: `metro_stop(): pthread_cancel() failed; ... specified
thread does not exist` during modal/menu/switch activity. Startup JACK logs also
contain xruns; zero-xrun claims below apply only to the measured windows.

## Shutdown clarification: RESTART clears the remembered script

After the run, the user recalled likely selecting RESTART before the later
power cycle. The target's source was fetched again, read-only, and confirms:

- `lua/core/norns.lua`, `_norns.restart`: calls `norns.script.clear()` **before**
  setting `clean_shutdown = true` and saving state.
- `lua/core/script.lua`, `Script.clear`: sets `norns.state.script = ''`.
- `lua/core/norns.lua`, `norns.shutdown` (SLEEP): marks a clean shutdown and saves
  the current script **before** calling its cleanup; it does not call
  `Script.clear()` in that path.
- `lua/core/state.lua`, `state.resume`: reloads a saved script only if
  `clean_shutdown` is true and the script path is nonempty and still exists.

Consequently, **RESTART → shutdown/power cycle without selecting another script**
is expected to return to `NO SCRIPT`. **Loaded script → SLEEP → power-on** is
expected to reload that script. This reload runs script initialization; parameter
or musical-session recall still follows that script's own persistence policy.

This source-derived explanation fits the recorded hook ordering and the user's
clarification. It supersedes the initial shutdown-path uncertainty as an
explanation for `NO SCRIPT`; a controlled direct-SLEEP recall test remains pending.
The original observations are preserved unchanged in the raw evidence.

## Performance

One window per condition; two-second warm-up, no concurrent menu stats reader,
internal clock, fixed four-note sequins pattern `{0,3,7,10}` rooted at MIDI 48,
one event per sixteenth. Script amplitude 0.15 at 120 BPM; 0.5 at 300 BPM.
Tone measured at 440 Hz / amp 0.2 with its persistent single synth. No audio
capture ran concurrently with performance measurement.

DSP is total JACK load sampled every 250 ms, not engine-only CPU. Lateness is
Lua sequence-clock dispatch versus the intended beat grid, converted to ms;
it is not acoustic onset latency. P95 uses nearest rank. Full samples and the
derivation are in [summary.json](evidence/summary.json) and `summarize.py`.

| Workload | Window | DSP mean / sampled max | Xruns | Events | Lateness p95 / max |
|---|---:|---:|---:|---:|---:|
| Steps idle | 15.04 s | 8.80% / 9.43% | 0 | 0 | — |
| Steps playing 120 BPM | 15.04 s | 12.63% / 13.31% | 0 | 120 | 1.06 / 1.19 ms |
| Steps playing 300 BPM, max amp | 15.04 s | 17.49% / 17.82% | 0 | 300 | 1.15 / 1.17 ms |
| Tone idle | ~10 s | 9.59% / 9.73% | 0 | — | — |
| Tone held | ~10 s | 9.64% / 9.97% | 0 | — | — |

Dirty script updates were 7.98/s at 120 BPM (8 events/s) and 14.83/s at 300 BPM
(20 events/s, UI polling nominally 15/s). The separate native-refresh probe had
299 play events, mean interval 16.75 ms, p95 16.80 ms, maximum 20.50 ms. Short
menu-return/accept phases included queued bursts (some identical timestamps),
reinforcing that display-event delivery is not an exact 60 Hz contract.

These short, instrumented windows establish this workload on this target, not
sustained worst-case capacity or an unmodified-image Pi 3 comparison baseline.

## Evidence and reproduction

- `run.py`: SSH/scp plus matron/sclang websocket transport. Operations, command
  bodies and output go to `evidence/commands.jsonl` with controller UTC time.
  The first mod-disabling restart disconnected before the initial client logged
  its output; empty enabled/loaded lists were verified afterward. The client was
  corrected to retain later disconnects. Remote timestamps are also present;
  compare device and controller clocks cautiously.
- `checks.lua`: real-device assertions and scoped diagnostic wrappers, restored
  after each check. Uses target-version internal routing/metrics and Lua debug
  introspection; not production script APIs.
- `probe.lua`: separate native-refresh/modal probe. Its version with corrected
  screenshot paths was rerun; `probe.json` and screenshots are from that run.
- `audio.scd`: two-second capture into a temporary SC buffer at the engine bus;
  analyzes its middle second, then frees probe synth/buffer/SynthDef resources.
- `evidence/deployed/`: initial deployed snapshots. Five skeletons are verbatim;
  fault fixtures append explicit errors. Sidecar fragment appends only lexical
  state accessors. Later harness uploads are hash-labelled in the command log;
  current harness sources are alongside this report.
- `evidence/results.jsonl`: append-only device results, including initial false
  assertions and human confirmations. `probe.json` contains event timestamps.
- `evidence/journal-*.txt`: available post-power-on journal; pre-power-on journal
  did not survive reboot. Earlier REPL output and selected journal commands are
  preserved in `commands.jsonl`.
- PNGs: steps/tone/mod/menu and modal framebuffer captures, inspected locally.
- `evidence/audio-*.txt`: measured playing/stopped and held/released stereo bus
  summaries. No analog audio recording is claimed.

Install transport dependency in a local virtual environment, then from this
directory (default host is `10.0.0.138`):

```bash
python -m pip install -r ../../skills/noseda/scripts/requirements.txt
python run.py inventory
python run.py deploy
```

`deploy` refuses existing example/test directories. On the already tested device,
use the existing installation instead of rerunning deployment. Inspect/back up
the current session and mods before changing them. The command log preserves the
recorded execution trace; the following are the principal test calls in order:

```bash
# Disable all current mods and restart; verify empty loaded/enabled lists.
python run.py lua 'local m=require "core/mods"; for _,n in ipairs(m.enabled_mod_names()) do m.set_enabled(n,false) end; m.save_enabled(); _norns.restart()'
python run.py --wait 5 load modern_steps/modern_steps.lua
python run.py --wait 4 lua 'dofile(_path.code.."noseda_acceptance/checks.lua").script()'
python run.py --wait 4 lua 'dofile(_path.code.."noseda_acceptance/checks.lua").state()'
python run.py --wait 6 lua 'dofile(_path.code.."noseda_acceptance/checks.lua").menu_pset()'
python run.py lua 'dofile(_path.code.."noseda_acceptance/checks.lua").pmap()'
# Reload: script() explicitly tests cleanup and stops its UI clock.
python run.py --wait 5 load modern_steps/modern_steps.lua
python run.py --wait 20 lua 'params:set("clock_tempo",120); dofile(_path.code.."noseda_acceptance/checks.lua").measure("idle",15,false,false)'
python run.py --wait 20 lua 'dofile(_path.code.."noseda_acceptance/checks.lua").measure("playing-120",15,true,false)'
python run.py --wait 20 lua 'dofile(_path.code.."noseda_acceptance/checks.lua").measure("playing-300-max-amp",15,true,true)'
python run.py --wait 5 load modern_tone/modern_tone.lua
python run.py --wait 4 lua 'dofile(_path.code.."noseda_acceptance/checks.lua").tone()'
python run.py upload audio.scd
python run.py lua 'params:set("noseda_tone_hz",440); params:set("noseda_tone_amp",0.2); _norns.key(3,1)'
python run.py --wait 6 sc '~acceptLabel="tone-held"; "/home/we/dust/code/noseda_acceptance/audio.scd".load;'
python run.py lua '_norns.key(3,0)'
python run.py --wait 6 sc '~acceptLabel="tone-released"; "/home/we/dust/code/noseda_acceptance/audio.scd".load;'
python run.py --wait 27 load noseda_acceptance/probe.lua
python run.py cycles
```

Mod phase: enable only `modern_counter`, restart, load awake then tone, invoke
`checks.mod()`, install hook observers, exercise the two fault fixtures, then
load tone/steps for human checks. The user operated the mod menu, reported
SLEEP/power-on, and later recalled likely restarting norns first. Verify postboot
state, disable the example mod, restart, and verify it is unloaded. The exact
commands, range reads, audio/performance calls,
faults, and cleanup checks are retained in the command log.

```bash
python run.py collect
python summarize.py
```

## Final device state and follow-ups

- Original `system.mods` restored byte-for-byte; all eight original mods loaded,
  example mod unloaded. Original mixer/tempo state restored, `speech/speech.lua`
  loaded, menu active, tempo 90. Main/sclang/JACK services active. Existing core
  modification list matches discovery.
- Restoring the original configuration exposed an `norns-uc4` `uc4 map params`
  hook error at `lib/uc4.lua:605` while loading speech. This occurred after the
  isolated tests; its prior occurrence/cause was not established here.
- Example/test code and owned test data remain installed for reproduction;
  backups are in `dust/data/noseda_acceptance/`. Harness PSET writes were confined
  to newly created example directories. Stock `awake` was also loaded for the
  unrelated-script mod check and ran its own lifecycle.
- Repeat on a verifiably unmodified stable image before checking off that
  roadmap baseline; compare the cancellation failure there.
- Verify loaded script → direct SLEEP → power-on recall with persistent logs.
  `NO SCRIPT` after an earlier RESTART is source-expected and is not classified
  as a resume failure.
- Physical-controller PMAP and Grid-specific LED/hotplug behavior remain
  untested. **A Grid is not required for these three skeletons.**
