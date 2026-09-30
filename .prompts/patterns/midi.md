# MIDI Output Patterns and Pitfalls

## Note-off bookkeeping for a sequencer track

Keep one "sounding note" record per track, send its note-off **once**, and
clear it:

```lua
local sounding = {}  -- [track] = { dev, note, vel, ch, start_pos, length, chord }

local function note_off(tr)
  local s = sounding[tr]
  if not s then return end
  midi_out[s.dev]:note_off(s.note, s.vel, s.ch)
  for _, n in ipairs(s.chord_notes or {}) do midi_out[s.dev]:note_off(n, s.vel, s.ch) end
  sounding[tr] = nil          -- the important line
end

-- every tick:
local s = sounding[tr]
if s and (pos > s.start_pos + s.length or pos < s.start_pos) then  -- ended, or pattern wrapped
  note_off(tr)
end
-- on a new note:
note_off(tr)                   -- end the previous note first
midi_out[dev]:note_on(note, vel, ch)
sounding[tr] = { ... }
```

Pitfalls this avoids, all found in a real script:

- **Note-off sent every tick:** if the record isn't cleared, the note-off (plus
  one per chord note) repeats on every tick until the next note. At 128 ppqn,
  one short note gave ~250 note-offs per bar, enough to saturate DIN MIDI with
  a few chord tracks, or to back up a virtual port until writes block.
- **Hanging notes on overlap:** a new note overwrote the record without ending
  the old one.
- **Hanging notes across the pattern end:** `pos > start + length` never
  becomes true once the position wraps back to 1. Also end the note when
  `pos < start`.
- On stop, end all sounding notes (and consider an all-notes-off CC).

## Testing MIDI output without hardware

Replace the vport methods, **keeping the originals**. They are fields on each
`midi.vports[i]` table, so setting them to nil deletes them:

```lua
local vp = midi.vports[1]
local orig_on, orig_off = vp.note_on, vp.note_off
vp.note_on  = function(self, n, v, ch) log_on[#log_on + 1] = n end
vp.note_off = function(self, n, v, ch) log_off[#log_off + 1] = n end
-- run the sequencer step directly for N ticks, then:
vp.note_on, vp.note_off = orig_on, orig_off
```

Check that every note-on gets exactly one note-off: no note-off for a note
that isn't sounding, and nothing left sounding except the last note. Check
which device is on vport 1 first (`midi.vports[1].name`): a mod such as nb_fluid
may have put a software synth there.

## Chords

`musicutil.generate_chord(root, name)` returns a new table on every call, and
a nil name silently means "Major". Map the UI's chord index to names so that
the index shown and the chord played agree (off-by-one mistakes are easy with
Lua's 1-based tables), and memoize by `[chord][root]` rather than caching per step.
