-- modern_tone: persistent sine voice
-- v1.0.0 @yourname
-- https://monome.org/docs/norns/engine-study-1/
-- Hold K3: sound; E2: frequency; E3: amplitude

engine.name = 'NoSEDATone'
local tone = include('lib/noseda_tone_engine')

function init()
  tone.add_params(function() redraw() end)
  params:bang()
end

function enc(n, d)
  if n == 2 then params:delta('noseda_tone_hz', d)
  elseif n == 3 then params:delta('noseda_tone_amp', d) end
end

function key(n, z)
  if n == 3 then engine.gate(z) end
end

function redraw()
  screen.clear()
  screen.level(15)
  screen.move(8, 20)
  screen.text('hold K3 to play')
  screen.move(8, 36)
  screen.text(params:string('noseda_tone_hz'))
  screen.move(8, 52)
  screen.text(params:string('noseda_tone_amp'))
  screen.update()
end
