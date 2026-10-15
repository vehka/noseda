-- modern_counter: example utility mod
local mods = require 'core/mods'
local mod_name = mods.this_name
local starts = 0
local logging = true

mods.hook.register('script_post_init', mod_name .. ':count', function()
  starts = starts + 1
  if logging then print(mod_name .. ': script starts = ' .. starts) end
end)

local menu = {}
function menu.init() end
function menu.deinit() end

function menu.key(n, z)
  if n == 2 and z == 1 then mods.menu.exit() end
end

function menu.enc(n, d)
  if n == 3 and d ~= 0 then
    logging = d > 0
    mods.menu.redraw()
  end
end

function menu.redraw()
  screen.clear()
  screen.level(15)
  screen.move(8, 20)
  screen.text('script starts: ' .. starts)
  screen.move(8, 36)
  screen.text('logging: ' .. (logging and 'on' or 'off'))
  screen.move(8, 52)
  screen.text('E3: logging / K2: back')
  screen.update()
end

mods.menu.register(mod_name, menu)

local Counter = {}
function Counter.get_count() return starts end
return Counter
