# Performance Work on norns

How to find and prove performance problems in norns scripts and engines.
Measure before and after on the real target (a Pi 3 / Pi 4 norns), and compare
revisions under identical conditions. See `tasks/debug.md` for reaching the
device.

## What to measure

- **Lua time per tick:** wrap the hot function (a sequencer step, a clock
  callback) and time it with `util.time()`: avg, p99, max, and the count over
  budget. At N pulses per beat and B bpm, the budget per tick is
  `60 / B / N` s (3.9 ms at 128 ppqn, 120 bpm).
- **Ticks actually run.** `clock.sync()` does not queue up missed ticks. When a
  coroutine is late, the ticks in between are skipped, so a "how late did this
  tick wake up" metric stays near zero even when the sequencer is drowning.
  Count the calls and compare with `seconds × bpm / 60 × ppqn`. This is the
  most honest sequencer metric.
- **Audio xruns:** `_norns.audio_get_xrun_count()` returns the count since the
  last call and **resets it**. The home menu also reads it while visible, so
  keep the menu closed during a run. Poll it every 0.25 s from a clock.
- **DSP load:** `_norns.audio_get_cpu_load()` is the JACK DSP load in percent.
- **Who caused an xrun:** `journalctl -u norns-jack --since '<time>' | grep -i xrun`.
  Lines like `client = SuperCollider was not finished` name the late client
  (SuperCollider = the engine; crone/softcut are norns' own).
- **Lua memory:** `collectgarbage("count")`. Allocating tables in hot paths
  means garbage-collection pauses later.
- **Idle baseline:** script loaded, transport stopped, 30 s of xruns and DSP
  load. This separates the engine's own cost from the cost of playing notes.

## Procedure for a fair comparison

1. Same device, tempo, duration and seeded pattern (`math.randomseed`) for
   every revision.
2. Restart norns before each revision (before each run on a desktop). State
   carries over: a backed-up MIDI port or engine state slows later runs.
   Interleave or repeat runs to catch drift that is really process state.
3. Reload the script before each run.
4. Keep the results with the revision measured (commit hash) and the machine.
5. Read xruns together with ticks run. A starved sequencer plays fewer notes,
   so the engine does less and shows *fewer* xruns. That doesn't mean it's better.

A synthetic stress pattern (every track on, locks, chords, LFOs) at two levels,
"normal" and "heavy", shows the trend quickly. Add a "realistic" level to find
where problems start.

## Common costs in Lua (norns scripts)

- **MIDI output:** each message is a system call. A bug that re-sends messages
  every tick (e.g. note-offs that are never marked as sent) can flood a DIN
  port (about 1000 msgs/s max) or back up a virtual port until writes block,
  giving stalls of 100 ms or more.
- **Building tables in hot paths:** `musicutil.generate_chord()` and similar
  return a new table on every call. Memoize by the inputs (e.g. by chord type
  and root note) instead of caching per step. A per-step cache goes stale
  whenever values change without going through the edit path (rules, MIDI
  recording, inherited defaults, loaded files).
- **`params:get()` / `params:set()` in hot loops:** cache rarely-changing
  values in locals, updated by the param's action. `params:set()` also runs the
  param action, which may send engine commands.
- **Skip idle work early:** muted or empty tracks, but keep what still has to
  happen (pending note-offs).

## Common costs in the audio engine (SuperCollider)

- Effects that run all the time (reverb, delay, compressor, send buses) cost
  DSP even when nothing plays. Measure the idle baseline, then remove effects
  one at a time.
- Voices that are never freed (no `doneAction: 2`) or that are allocated up
  front for every sample slot.
- On a Pi 3 at 128-frame buffers the headroom is small. Watch the DSP load
  and the xrun counts, not just whether it "sounds OK".

## Profiling tools inside a script

Keep profiling instrumentation behind a flag with ~zero cost when off
(`if ENABLE_PROFILING then … end`), exposed as params (enable / print / reset),
and have it append its report to a file under `norns.state.data`. Keep it on
its own branch if the script is headed upstream.

## Offline micro-benchmarks

Plain `lua5.3` with `package.path` pointing at `<norns>/lua/lib/` can load
`util` and `musicutil` for correctness checks and microbenchmarks on the
desktop. Desktop speed is not Pi speed, so use it for ratios only.
