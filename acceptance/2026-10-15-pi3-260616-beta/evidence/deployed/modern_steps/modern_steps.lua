-- modern_steps: four-note instrument
-- v1.0.0 @yourname
-- https://monome.org/docs/norns/clocks/
-- K2: reset notes; K3: play/stop
-- E2: root note; E3: amplitude

engine.name = 'PolyPerc'
local musicutil = require 'musicutil'
local s = require 'sequins'

local notes = s{0, 3, 7, 10}
local root = 48
local running = false
local dirty = true
local sequence_clock, ui_clock

local function stop()
  running = false
  if sequence_clock then
    clock.cancel(sequence_clock)
    sequence_clock = nil
  end
  dirty = true
end

local function start()
  if sequence_clock then return end
  running = true
  sequence_clock = clock.run(function()
    while true do
      clock.sync(1/4) -- sixteenth notes; first note waits for this grid
      engine.hz(musicutil.note_num_to_freq(root + notes()))
      dirty = true
    end
  end)
  dirty = true
end

function init()
  params:add_group('modern_steps', 'modern steps', 2)
  params:add_number('modern_steps_root', 'root note', 24, 84, 48)
  params:set_action('modern_steps_root', function(value)
    root = value
    dirty = true
  end)
  params:add_control('modern_steps_amp', 'amplitude',
    controlspec.new(0, 0.5, 'lin', 0, 0.15))
  params:set_action('modern_steps_amp', function(value)
    engine.amp(value)
    dirty = true
  end)
  ui_clock = clock.run(function()
    while true do
      clock.sleep(1/15)
      if dirty then
        redraw()
        dirty = false
      end
    end
  end)
  clock.transport.start = start -- these don't reset the underlying clock
  clock.transport.stop = stop
  params:bang()
end

function enc(n, d)
  if n == 2 then params:delta('modern_steps_root', d)
  elseif n == 3 then params:delta('modern_steps_amp', d) end
end

function key(n, z)
  if z ~= 1 then return end
  if n == 2 then notes:reset(); dirty = true
  elseif n == 3 then
    if running then stop() else start() end
  end
end

function redraw()
  screen.clear()
  screen.level(15)
  screen.move(8, 20)
  screen.text(running and 'playing' or 'stopped')
  screen.move(8, 36)
  screen.text('root: ' .. params:string('modern_steps_root'))
  screen.move(8, 52)
  screen.text('amp: ' .. params:string('modern_steps_amp'))
  screen.update()
end

function cleanup()
  stop()
  if ui_clock then clock.cancel(ui_clock); ui_clock = nil end
end
