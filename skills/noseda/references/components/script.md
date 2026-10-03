# Norns Script Development

## Script Structure

A norns script is a Lua application that runs on the norns platform. Every script MUST follow this structure:

```
myscript/
├── myscript.lua              # Main script file (REQUIRED)
├── lib/                       # Library modules (OPTIONAL)
│   ├── sequencer.lua
│   └── ui.lua
└── data/                      # Saved data (OPTIONAL, created at runtime)
    └── myscript.pset         # Parameter sets
```

## Essential Components

### Main Script File

The main script file must be named to match the directory name and include:

```lua
-- scriptname: My Script
-- v1.0.0 @author
-- Description of what the script does
--
-- Key 1: Function
-- Enc 1: Parameter
-- etc.

engine.name = 'PolySub'  -- Optional: specify engine

local musicutil = require 'musicutil'  -- Optional: require libraries

-- State variables
local position = 1
local notes = {}

-- Required: initialization
function init()
  -- Set up parameters, start clocks, etc.
  screen.aa(1)  -- Anti-aliasing on
  redraw()
end

-- Required: cleanup
function cleanup()
  -- Stop clocks, close files, etc.
end

-- Required: draw screen
function redraw()
  screen.clear()
  screen.level(15)
  screen.move(10, 30)
  screen.text("Hello Norns")
  screen.update()
end

-- Input handlers
function enc(n, delta)
  -- Handle encoder input
  if n == 1 then
    -- Enc 1
  elseif n == 2 then
    -- Enc 2
  elseif n == 3 then
    -- Enc 3
  end
  redraw()
end

function key(n, z)
  -- Handle key input
  if n == 2 and z == 1 then
    -- Key 2 pressed
  elseif n == 3 and z == 1 then
    -- Key 3 pressed
  end
  redraw()
end
```

### Using Parameters

The params system provides saveable controls:

```lua
function init()
  -- Add parameters
  params:add_number("tempo", "Tempo", 60, 300, 120)
  params:add_option("scale", "Scale", {"Major", "Minor", "Dorian"}, 1)

  -- Set parameter actions
  params:set_action("tempo", function(x)
    clock.tempo = x / 60
  end)

  -- Read parameter from PSET menu
  params:read()

  -- Auto-write parameter saves
  params:bang()
end
```

### Using Clocks

Clocks provide timing and scheduling:

```lua
local clock_id

function init()
  clock_id = clock.run(tick)
end

function tick()
  while true do
    clock.sync(1/4)  -- Sync to quarter notes
    -- Do something rhythmic
    redraw()
  end
end

function cleanup()
  clock.cancel(clock_id)
end
```

## Common Patterns

### Library Module (lib/mylib.lua)

```lua
local MyLib = {}

function MyLib.new()
  local self = {}

  self.value = 0

  self.set = function(v)
    self.value = v
  end

  return self
end

return MyLib
```

### Using in Main Script

```lua
local MyLib = require 'lib/mylib'
local obj = MyLib.new()
```

## Screen Drawing

### Basic Drawing
```lua
function redraw()
  screen.clear()

  -- Set drawing level (0-15, 15 is brightest)
  screen.level(15)

  -- Draw text
  screen.move(x, y)
  screen.text("hello")
  screen.text_center("centered")

  -- Draw shapes
  screen.move(x1, y1)
  screen.line(x2, y2)
  screen.stroke()

  screen.circle(x, y, radius)
  screen.fill()

  screen.rect(x, y, width, height)
  screen.stroke()

  -- Update display
  screen.update()
end
```

## Key Reference Files to Examine

When developing scripts, examine these reference implementations:

1. **Basic script patterns:**
   - `../norns/scripts/awake.lua` - Sequencer example
   - `../norns/scripts/first.lua` - Minimal example

2. **Advanced patterns:**
   - Scripts using midi, grid, arc in `../norns/scripts/`

3. **Library references:**
   - `../norns/lua/core/` - Core library implementations
   - Look at `musicutil`, `tab`, `util` for common utilities

## Testing Checklist

- [ ] Script initializes without errors
- [ ] All encoders respond appropriately
- [ ] All keys respond appropriately
- [ ] Screen updates correctly
- [ ] Parameters save/load correctly
- [ ] Cleanup properly releases resources
- [ ] No global variable pollution (use local)
- [ ] Comments explain non-obvious code
- [ ] Script header documents controls

## Common Mistakes to Avoid

1. **Forgetting screen.update()**: Screen won't refresh
2. **Not using local variables**: Pollutes global namespace
3. **Blocking in main thread**: Use clocks for timing
4. **Not implementing cleanup()**: Resources may leak
5. **Hardcoding tempo**: Use clock.sync() to respect global tempo

## Script Metadata

Include at the top of your script:

```lua
-- scriptname: Your Script Name
-- v1.0.0 @yourname
--
-- Brief description of functionality
--
-- Documentation of controls:
-- KEY2: Start/Stop
-- KEY3: Reset
-- ENC2: Tempo
-- ENC3: Pattern
```
