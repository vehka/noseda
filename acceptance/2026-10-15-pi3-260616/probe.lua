-- Purpose-built hardware refresh/modal probe, distinct from the skeletons.
local te = require 'textentry'
local fs = require 'fileselect'
local directory = _path.data .. 'noseda_acceptance/'
local stats = {refresh={},draws={},phase='play',modal=false,callbacks={}}
local dirty=true
function refresh()
  local p=stats.phase
  stats.refresh[p]=stats.refresh[p] or {}
  table.insert(stats.refresh[p], util.time())
  if not stats.modal and dirty then redraw(); dirty=false end
end
function redraw()
  stats.draws[stats.phase]=(stats.draws[stats.phase] or 0)+1
  screen.clear(); screen.level(15); screen.move(8,20)
  screen.text('refresh acceptance'); screen.move(8,40); screen.text(stats.phase)
  screen.update()
end
local function shot(name) screen.export_screenshot('../'..name) end
local function phase(name) stats.phase=name; dirty=true end
function init()
  clock.run(function()
    clock.sleep(5); shot('refresh-play')
    phase('menu'); _menu.set_mode(true); _menu.set_page('PARAMS')
    clock.sleep(3); shot('refresh-menu')
    _menu.set_mode(false); phase('returned'); clock.sleep(3)
    phase('textentry'); stats.modal=true
    te.enter(function(value) stats.callbacks.textentry=tostring(value); stats.modal=false end,'acceptance','modal acceptance')
    clock.sleep(3); shot('refresh-textentry')
    _norns.key(2,1); _norns.key(2,0)
    phase('textentry_accept'); stats.modal=true
    te.enter(function(value) stats.callbacks.accept=value; stats.modal=false end,'accepted','accept acceptance')
    clock.sleep(1); _norns.key(3,1); _norns.key(3,0)
    phase('fileselect'); stats.modal=true
    fs.enter(directory,function(value) stats.callbacks.fileselect=value; stats.modal=false end)
    clock.sleep(3); shot('refresh-fileselect'); _norns.key(2,1); _norns.key(2,0)
    phase('final'); clock.sleep(3); shot('refresh-final')
    local f=assert(io.open(directory..'probe.json','w')); f:write(_json.encode(stats)); f:close()
    print('ACCEPT probe complete',_json.encode(stats.callbacks))
  end)
end
function enc() dirty=true end
function key() dirty=true end
