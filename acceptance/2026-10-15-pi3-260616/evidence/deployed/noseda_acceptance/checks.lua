-- Target-version diagnostic entry points, not production norns integration.
local A = {}
local directory = _path.data .. 'noseda_acceptance/'
local function save(name, ok, result)
  local record = {name = name, ok = ok, result = result, time = util.time(), script = norns.state.script}
  local f = assert(io.open(directory .. 'results.jsonl', 'a'))
  f:write(_json.encode(record), '\n'); f:close()
  print('ACCEPT', name, ok and 'PASS' or 'FAIL', _json.encode(result))
end
local function run(name, fn)
  return clock.run(function()
    local ok, result = xpcall(fn, debug.traceback)
    save(name, ok, result or {})
  end)
end
local function up(fn, name, value, replace)
  for i = 1, 40 do
    local n, v = debug.getupvalue(fn, i)
    if not n then break end
    if n == name then
      if replace then debug.setupvalue(fn, i, value) end
      return v
    end
  end
  error('missing upvalue: ' .. name)
end
local function press(n) _norns.key(n, 1); _norns.key(n, 0) end
local function approx(a, b) assert(math.abs(a-b)<0.00001, tostring(a)..' ~= '..tostring(b)) end
local function shot(name) screen.export_screenshot('../noseda_acceptance/' .. name) end

function A.script()
  run('script-controls-transport-pset', function()
    assert(engine.name == 'PolyPerc' and not _menu.mode)
    approx(params:get('modern_steps_root'), 48)
    local initial_amp = params:get('modern_steps_amp')
    norns.encoders.callback(2, 1)
    assert(params:get('modern_steps_root') == 49)
    norns.encoders.callback(3, 1)
    assert(params:get('modern_steps_amp') > initial_amp)
    params:set('modern_steps_root', 55); params:set('modern_steps_amp', 0.2)
    params:write(91, 'acceptance-api')
    params:set('modern_steps_root', 40); params:set('modern_steps_amp', 0.05)
    params:read(91)
    approx(params:get('modern_steps_root'), 55); approx(params:get('modern_steps_amp'), 0.2)
    approx(up(clock.transport.start, 'root'), 55)
    for i=1,12 do
      clock.transport.start()
      local first = up(clock.transport.start, 'sequence_clock')
      clock.transport.start(); assert(first == up(clock.transport.start, 'sequence_clock'))
      clock.sleep(0.03)
      clock.transport.stop(); clock.transport.stop()
      assert(not up(clock.transport.start, 'sequence_clock'))
    end
    press(3); assert(up(clock.transport.start, 'running'))
    clock.sleep(0.5); press(2)
    local notes = up(key, 'notes')
    -- Sequins reset index is verified before the next scheduled event.
    assert(notes.qix == 1)
    press(3); assert(not up(clock.transport.start, 'running'))
    clock.sleep(0.15); shot('steps-stopped')
    local owned_ui = up(cleanup, 'ui_clock')
    cleanup(); cleanup()
    assert(not clock.threads[owned_ui])
    return {cycles=12, root=params:get('modern_steps_root'), amp=params:get('modern_steps_amp'), cleanup='twice'}
  end)
end

function A.state()
  run('sidecar-and-pset-semantics', function()
    local sidecar = dofile(_path.code .. 'noseda_acceptance/sidecar.lua')
    sidecar.install()
    local path = norns.state.data .. norns.state.shortname .. '-92.pset'
    sidecar.set({61,65,68,73}); params:write(92, 'sidecar')
    sidecar.set({1}); params:read(92)
    assert(sidecar.get()[1] == 61 and #sidecar.get()==4)
    os.remove(path .. '.state'); sidecar.set({2}); params:read(92)
    assert(sidecar.get()[1]==60 and #sidecar.get()==4)
    tab.save({schema=0,steps={1}},path..'.state'); params:read(92)
    assert(sidecar.get()[1]==60)
    local f=assert(io.open(path..'.state','w')); f:write('invalid lua !!!'); f:close()
    params:read(92); assert(sidecar.get()[1]==60)
    sidecar.set({62,66,69,74}); params:write(92, 'sidecar')
    params:delete(92); clock.sleep(1)
    assert(not util.file_exists(path) and not util.file_exists(path..'.state'))
    local count = 0
    local p = params:lookup_param('modern_steps_root')
    local original = p.action
    p.action = function(v) count=count+1; original(v) end
    local ok, err = xpcall(function()
      params:set('modern_steps_root', 63); params:write(93,'silent')
      params:set('modern_steps_root',48); count=0
      params:read(93,true); assert(count==0)
      approx(up(clock.transport.start,'root'),48)
      params:bang(); assert(count==1); approx(up(clock.transport.start,'root'),63)
    end, debug.traceback)
    p.action=original
    assert(ok,err)
    params.action_write=nil; params.action_read=nil; params.action_delete=nil
    return {roundtrip=true, missing=true, older=true, corrupt=true, delete=true, silent_then_bang=true}
  end)
end

function A.menu_pset()
  run('params-menu-save-recall-delete', function()
    params:set('modern_steps_root',59)
    _menu.set_mode(true); _menu.set_page('PARAMS')
    local m=_menu.m.PARAMS
    m.mode=0; m.mode_pos=2; press(3); clock.sleep(1)
    m.ps_pos=0; m.ps_action=1; press(3)
    local te=require 'textentry'
    te.txt='acceptance-menu'; te.row=1; te.delok=1; press(3)
    clock.sleep(1)
    assert(util.file_exists(norns.state.data .. 'modern_steps-01.pset'))
    assert(norns.state.pset_last==1)
    params:set('modern_steps_root',35)
    m.ps_pos=0; m.ps_action=2; press(3)
    assert(params:get('modern_steps_root')==59)
    shot('params-pset')
    m.ps_action=3; press(3); press(3); clock.sleep(1)
    assert(not util.file_exists(norns.state.data .. 'modern_steps-01.pset'))
    _menu.set_mode(false)
    return {save=true, recall=true, delete=true, pset_last=1}
  end)
end

function A.pmap()
  run('pmap-injected-cc-roundtrip', function()
    local p=norns.pmap
    p.new('modern_steps_root')
    p.data.modern_steps_root.out_lo=24; p.data.modern_steps_root.out_hi=84
    p.assign('modern_steps_root',1,1,21)
    p.write(); p.clear(); p.read()
    assert(p.rev[1][1][21]=='modern_steps_root')
    -- Core PMAP dispatch at the menu MIDI hook; no physical controller claimed.
    norns.menu_midi_event({0xb0,21,127},1)
    assert(params:get('modern_steps_root')==84)
    norns.menu_midi_event({0xb0,21,0},1)
    assert(params:get('modern_steps_root')==24)
    p.clear(); os.remove(norns.state.data..norns.state.shortname..'.pmap')
    return {cc=21, minimum=24, maximum=84, physical_controller=false}
  end)
end

function A.measure(label, seconds, playing, high)
  run('performance-'..label, function()
    local start=clock.transport.start
    if high then params:set('clock_tempo',300); params:set('modern_steps_amp',0.5) end
    if playing then start() else clock.transport.stop() end
    clock.sleep(2)
    local thread=up(start,'sequence_clock')
    local original_resume=clock.resume
    local events, samples, draws={}, {}, {}
    local original_update=screen.update
    local beat0=clock.get_beats()
    local next_beat=math.floor(beat0*4+1)/4
    clock.resume=function(id,...)
      if id==thread then
        events[#events+1]={time=util.time(),beat=clock.get_beats(),target=next_beat}
        next_beat=next_beat+0.25
      end
      return original_resume(id,...)
    end
    screen.update=function(...) draws[#draws+1]=util.time(); return original_update(...) end
    local ok,result=xpcall(function()
      local reset_xruns=_norns.audio_get_xrun_count()
      local t0=util.time()
      while util.time()-t0 < seconds do
        samples[#samples+1]={time=util.time(),dsp=_norns.audio_get_cpu_load()}
        clock.sleep(0.25)
      end
      return {seconds=util.time()-t0, bpm=params:get('clock_tempo'), playing=playing,
              discarded_xruns=reset_xruns, xruns=_norns.audio_get_xrun_count(),
              events=events, samples=samples, draws=draws, beat0=beat0}
    end,debug.traceback)
    clock.resume=original_resume; screen.update=original_update
    clock.transport.stop()
    assert(ok,result)
    return result
  end)
end

function A.tone()
  run('engine-host-controls-pset', function()
    assert(engine.name=='NoSEDATone' and not _menu.mode)
    approx(params:get('noseda_tone_hz'),220); approx(params:get('noseda_tone_amp'),0.15)
    norns.encoders.callback(2,1); assert(params:get('noseda_tone_hz')>220)
    norns.encoders.callback(3,1); assert(params:get('noseda_tone_amp')>0.15)
    params:set('noseda_tone_hz',440); params:set('noseda_tone_amp',0.2)
    params:write(91,'tone'); params:set('noseda_tone_hz',1000); params:read(91)
    approx(params:get('noseda_tone_hz'),440)
    for i=1,24 do press(3); clock.sleep(0.01) end
    engine.hz(1); engine.amp(-1); engine.gate(-1); clock.sleep(0.1)
    engine.hz(9000); engine.amp(1); engine.gate(2); clock.sleep(0.1)
    engine.gate(0); params:bang(); clock.sleep(0.1)
    shot('tone')
    return {gate_cycles=24, parameter_roundtrip=true, out_of_range_commands='sent; inspect SC controls separately'}
  end)
end

function A.mod()
  run('mod-menu-and-cached-state', function()
    local mods=require 'core/mods'
    assert(#mods.loaded_mod_names()==1 and mods.is_loaded('modern_counter'))
    local counter=require 'modern_counter/lib/mod'
    local count=counter.get_count()
    assert(count>=1)
    _menu.set_mode(true); _menu.set_page('MODS')
    local m=_menu.m.MODS
    for i,name in ipairs(m.list) do if name=='modern_counter' then m.pos=i-1; m.select_position(m.pos) end end
    press(3); assert(_menu.page=='modern_counter')
    norns.encoders.callback(3,-1); shot('counter-logging-off')
    norns.encoders.callback(3,1); shot('counter-logging-on')
    press(2); assert(_menu.page=='MODS')
    _menu.set_mode(false)
    return {count=count, menu=true, logging_toggle=true}
  end)
end

function A.cleanup_check()
  run('cleared-script-resources',function()
    assert(engine.name==nil and clock.transport.start==nil and clock.transport.stop==nil)
    -- This check's own coroutine is the only permitted clock thread.
    local count=0; for _ in pairs(clock.threads) do count=count+1 end
    assert(count==1, 'remaining clocks: '..count)
    return {clock_threads_excluding_harness=count-1, engine=tostring(engine.name)}
  end)
end
return A
