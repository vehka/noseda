# Norns Mod Development

## Mod Structure

A norns mod is a Lua module that extends or modifies the norns system globally. Every mod MUST follow this structure:

```
mymod/
├── lib/
│   └── mod.lua               # Main mod file (REQUIRED)
└── README.md                 # Documentation (RECOMMENDED)
```

**Critical**: The file MUST be located at `lib/mod.lua` for norns to recognize it as a mod.

## Mod File Template

```lua
-- mymod
-- v1.0.0 @author
-- Description of what the mod does

local mod = require 'core/mods'

-- Check if mod is installed
if note then
  return
end

local MyMod = {}

-- Initialize mod
function MyMod.init()
  print("MyMod: initializing")
  -- Setup code here
end

-- Hook: system_post_startup
-- Called after matron initialization, before scripts run
function MyMod.system_post_startup()
  print("MyMod: system started")
  -- System-level initialization
end

-- Hook: system_pre_shutdown
-- Called when entering sleep mode
function MyMod.system_pre_shutdown()
  print("MyMod: system shutting down")
  -- Cleanup before shutdown
end

-- Hook: script_pre_init
-- Called before a script's engine and init() function
function MyMod.script_pre_init()
  print("MyMod: script pre-init")
  -- Prepare for script loading
end

-- Hook: script_post_init
-- Called after a script's init() function completes
function MyMod.script_post_init()
  print("MyMod: script initialized")
  -- Augment or modify loaded script
end

-- Hook: script_post_cleanup
-- Called after script termination
function MyMod.script_post_cleanup()
  print("MyMod: script cleaned up")
  -- Cleanup after script ends
end

-- Initialize the mod
MyMod.init()

-- Register hooks
mod.hook.register("system_post_startup", "mymod_system_post_startup", MyMod.system_post_startup)
mod.hook.register("system_pre_shutdown", "mymod_system_pre_shutdown", MyMod.system_pre_shutdown)
mod.hook.register("script_pre_init", "mymod_script_pre_init", MyMod.script_pre_init)
mod.hook.register("script_post_init", "mymod_script_post_init", MyMod.script_post_init)
mod.hook.register("script_post_cleanup", "mymod_script_post_cleanup", MyMod.script_post_cleanup)
```

## Lifecycle Hooks

Mods can register callback functions for these events:

### system_post_startup
- **When**: After matron initialization, before scripts run
- **Use for**: System-level modifications, global state setup
- **Example**: Adding menu items, initializing services

### system_pre_shutdown
- **When**: When entering sleep mode
- **Use for**: Cleanup, saving state
- **Example**: Closing connections, writing data

### script_pre_init
- **When**: Before a script's engine and init() function
- **Use for**: Preparing environment for script
- **Example**: Injecting dependencies, modifying globals

### script_post_init
- **When**: After a script's init() function completes
- **Use for**: Augmenting script functionality
- **Example**: Adding parameters, hooking into script functions

### script_post_cleanup
- **When**: After script termination
- **Use for**: Cleanup after script ends
- **Example**: Resetting state, freeing resources

## Common Mod Patterns

### Adding Menu Items

```lua
local mod = require 'core/mods'

function MyMod.menu()
  return {
    {type = "number", name = "setting1", min = 1, max = 10, default = 5},
    {type = "option", name = "mode", options = {"A", "B", "C"}, default = 1},
    {type = "trigger", name = "action", action = function()
      print("action triggered")
    end}
  }
end

mod.menu.register(mod.this_name, MyMod.menu)
```

### Augmenting Script Functions

```lua
function MyMod.script_post_init()
  -- Store original redraw function
  local original_redraw = redraw

  -- Replace with augmented version
  redraw = function()
    -- Call original
    original_redraw()

    -- Add custom drawing
    screen.move(100, 10)
    screen.text("MOD")
    screen.update()
  end
end
```

### Adding Global Utilities

```lua
-- Make utility available to all scripts
_G.myutil = {}

_G.myutil.helper = function(x)
  return x * 2
end
```

## Using Additional Library Files

Mods can require additional modules:

```
mymod/
├── lib/
│   ├── mod.lua               # Main mod file
│   ├── helper.lua            # Additional module
│   └── ui.lua                # Another module
```

In `lib/mod.lua`:
```lua
local helper = include('lib/helper')  -- Use include() for mod-local files
```

## Testing Checklist

- [ ] Mod file is at `lib/mod.lua`
- [ ] Mod loads without errors
- [ ] Hooks register successfully
- [ ] Mod functionality works across different scripts
- [ ] No conflicts with other mods
- [ ] Cleanup properly releases resources
- [ ] Menu items (if any) work correctly
- [ ] Documentation explains functionality

## Common Mistakes to Avoid

1. **Wrong file location**: Must be `lib/mod.lua`, not `mod.lua`
2. **Breaking existing scripts**: Test with multiple scripts
3. **Not cleaning up**: Implement proper cleanup in hooks
4. **Global pollution**: Be careful with globals, use `_G` explicitly
5. **Hook name conflicts**: Use unique, descriptive hook names

## Key Reference Files to Examine

When developing mods, examine these reference implementations:

1. **Mod system core:**
   - `../norns/lua/core/mods.lua` - Mod loading and hook system

2. **Example mods:**
   - https://github.com/monome/norns-example-mod - Basic template
   - Community mods on https://norns.community/

3. **Core libraries to understand:**
   - `../norns/lua/core/` - System libraries that can be extended

## Installation

Mods are installed in the norns `dust` directory:
```
dust/code/mymod/
└── lib/
    └── mod.lua
```

Enable/disable via: SYSTEM > MODS

## Documentation

Include a README.md with:
- Description of mod functionality
- Installation instructions
- Configuration options
- Known conflicts
- Version history
