local Tone = {}
Tone.specs = {
  hz = controlspec.new(40, 4000, 'exp', 0, 220, 'Hz'),
  amp = controlspec.new(0, 0.5, 'lin', 0, 0.15)
}

function Tone.add_params(on_change)
  params:add_group('noseda_tone', 'tone', 2)
  params:add_control('noseda_tone_hz', 'frequency', Tone.specs.hz)
  params:set_action('noseda_tone_hz', function(value)
    engine.hz(value)
    if on_change then on_change() end
  end)
  params:add_control('noseda_tone_amp', 'amplitude', Tone.specs.amp)
  params:set_action('noseda_tone_amp', function(value)
    engine.amp(value)
    if on_change then on_change() end
  end)
end

return Tone
