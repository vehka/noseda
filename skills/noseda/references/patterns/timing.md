# Timing Patterns and Pitfalls (clock)

## Sequencer loop on the global clock

```lua
function clocked_seq()
  while true do
    clock.sync(1/128)      -- one tick at 128 ppqn
    step()
  end
end
sequencer = clock.run(clocked_seq)
```

- **Don't add an extra `clock.sync()` at the end of an inner loop.** A common
  shape is `for i = 1, 256 do clock.sync(1/128) step(i) end` inside
  `while true`. One more `clock.sync(1/128)` after the `for` loop costs a whole
  tick every 256 ticks. The coroutine resumes exactly on a boundary, so the
  next `sync` waits a full period. Measured: 127.5 steps per beat instead of 128,
  so the sequence falls one beat behind the clock every 64 bars (256 beats).
  Check with a counter: steps run ÷ `clock.get_beats()` elapsed should equal ppqn.
- **Missed ticks are skipped, not queued.** If `step()` takes longer than a
  tick, `clock.sync` resumes at the next boundary still ahead, and the ticks in
  between never run. Lateness measured at wake-up stays small, so count steps
  to see whether the sequencer keeps up (see `tasks/optimize.md`).
- **Starting in phase:** with Link or crow clock, waiting for the bar before
  the loop (`clock.sync(4)`) keeps the pattern aligned with the external
  source. With MIDI clock, the start message already marks the downbeat. With
  the internal clock, starting at once feels more responsive.

## Transport callbacks

```lua
function clock.transport.start() ... end   -- called on external start, and yours to call
function clock.transport.stop()  ... end
```

- norns clears these on script cleanup. Define them as globals in the script.
- Decide explicitly whether play *continues* or *restarts*. A common
  convention: plain play continues, and a modifier + play restarts. Users rely
  on it, so don't change it silently.
- Cancelling the sequencer coroutine (`clock.cancel(id)`) while its resume is
  already queued can log `clock.lua: bad argument #1 to 'resume' (thread
  expected)`. That's a race in the norns clock scheduler; it's harmless and not
  a script bug.

## Timing budget

At B bpm and N ticks per beat, one tick is `60 / B / N` seconds: 3.9 ms at
120 bpm and 128 ppqn. Everything a step does (params, engine commands, MIDI,
table building) has to fit, on a Pi 3, with the audio engine using the same CPU.
