# Norns Engine Development

## Engine Overview

A norns engine is a SuperCollider class that provides audio synthesis capabilities to norns scripts. Engines run in the crone/SuperCollider environment and communicate with matron (Lua) via OSC commands.

## Engine Structure

```
myengine/
└── Engine_MyEngine.sc        # Engine file (REQUIRED, note capitalization)
```

**Naming Convention**: File must be named `Engine_[EngineName].sc` where EngineName matches the class name.

## Basic Engine Template

```supercollider
// Engine_MyEngine
// Simple example engine

Engine_MyEngine : CroneEngine {
    // Class variables
    var synth;
    var <amp = 0.5;
    var <freq = 440;

    // Constructor
    *new { arg context, doneCallback;
        ^super.new(context, doneCallback);
    }

    // Allocation - called once at engine start
    alloc {
        // Define synthesis
        SynthDef(\mysynth, {
            arg out, freq = 440, amp = 0.5, gate = 1;
            var sig, env;

            // Oscillator
            sig = SinOsc.ar(freq);

            // Envelope
            env = EnvGen.kr(Env.asr(0.01, 1, 0.1), gate, doneAction: 2);

            // Output
            Out.ar(out, sig * env * amp);
        }).add;

        // Register OSC commands
        this.addCommand(\start, "f", { arg msg;
            var note = msg[1];
            synth = Synth(\mysynth, [
                \out, context.out_b,
                \freq, note.midicps,
                \amp, amp
            ], target: context.xg);
        });

        this.addCommand(\stop, "", { arg msg;
            synth.set(\gate, 0);
        });

        this.addCommand(\amp, "f", { arg msg;
            amp = msg[1];
            synth.set(\amp, amp);
        });

        this.addCommand(\freq, "f", { arg msg;
            freq = msg[1];
            synth.set(\freq, freq);
        });
    }

    // Cleanup - called when engine stops
    free {
        synth.free;
    }
}
```

## Engine Components

### Class Definition
```supercollider
Engine_MyEngine : CroneEngine {
    // Must extend CroneEngine
}
```

### Constructor
```supercollider
*new { arg context, doneCallback;
    ^super.new(context, doneCallback);
}
```

### Allocation Method
The `alloc` method is where you:
1. Define SynthDefs
2. Register OSC commands
3. Set up synthesis structures

```supercollider
alloc {
    // Define synthesis
    SynthDef(\name, { /* ... */ }).add;

    // Register commands
    this.addCommand(\commandName, "types", { arg msg;
        // Handle command
    });
}
```

### Command Registration

Commands are how Lua scripts control the engine:

```supercollider
this.addCommand(\name, "argumentTypes", { arg msg;
    // msg[1] is first argument
    // msg[2] is second argument, etc.
});
```

**Argument Types:**
- `i` - integer
- `f` - float
- `s` - string
- `""` - no arguments

**Example:**
```supercollider
// Command with float and integer
this.addCommand(\note_on, "fi", { arg msg;
    var freq = msg[1];    // float
    var velocity = msg[2]; // integer
    // ...
});
```

### Audio Output

Always output to `context.out_b`:

```supercollider
Out.ar(out, signal);  // Where out = context.out_b

// Or in the Synth call:
Synth(\name, [\out, context.out_b, /* ... */]);
```

### Cleanup Method

Free resources when engine stops:

```supercollider
free {
    synth.free;
    group.free;
    // etc.
}
```

## Common Patterns

### Polyphonic Engine

```supercollider
Engine_Poly : CroneEngine {
    var group;

    alloc {
        group = ParGroup.tail(context.xg);

        SynthDef(\voice, { arg out, freq = 440;
            var sig = SinOsc.ar(freq);
            var env = EnvGen.kr(Env.perc, doneAction: 2);
            Out.ar(out, sig * env);
        }).add;

        this.addCommand(\note, "f", { arg msg;
            Synth(\voice, [
                \out, context.out_b,
                \freq, msg[1]
            ], target: group);
        });
    }

    free {
        group.free;
    }
}
```

### Parameter Storage

Store parameters as instance variables:

```supercollider
var <amp = 0.5;      // readable from outside
var <>cutoff = 1000; // readable and writable

this.addCommand(\amp, "f", { arg msg;
    amp = msg[1];
    synth.set(\amp, amp);
});
```

### Using Buffers

```supercollider
var buffer;

alloc {
    // Allocate buffer
    buffer = Buffer.alloc(context.server, 48000);

    this.addCommand(\read, "s", { arg msg;
        buffer.read(msg[1]);
    });
}

free {
    buffer.free;
}
```

## Lua Script Integration

Using an engine from a norns script:

```lua
-- Select engine at script start
engine.name = 'MyEngine'

function init()
    -- Send commands to engine
    engine.start(440)
    engine.amp(0.5)
end

-- Commands available as engine.commandname()
function key(n, z)
    if n == 2 and z == 1 then
        engine.start(math.random(200, 800))
    elseif n == 3 and z == 1 then
        engine.stop()
    end
end
```

## Key Reference Files to Examine

When developing engines, examine these reference implementations:

1. **Simple engines:**
   - `../norns/sc/engines/Engine_PolyPerc.sc` - Basic percussive engine
   - `../norns/sc/engines/Engine_TestSine.sc` - Minimal example

2. **Advanced engines:**
   - `../norns/sc/engines/Engine_PolySub.sc` - Polyphonic subtractive
   - Engines in community scripts

3. **SuperCollider references:**
   - `../norns/sc/core/` - Crone core classes
   - `../norns/sc/engines/` - All core engines

## Testing Checklist

- [ ] Engine file named correctly: `Engine_[Name].sc`
- [ ] Class extends CroneEngine
- [ ] Constructor calls super.new
- [ ] SynthDefs are added in alloc
- [ ] Commands registered with correct types
- [ ] Audio outputs to context.out_b
- [ ] Resources freed in free method
- [ ] Test from Lua script
- [ ] CPU usage is reasonable
- [ ] No audio artifacts or clicks

## Common Mistakes to Avoid

1. **Wrong file naming**: Must be `Engine_Name.sc` exactly
2. **Wrong output bus**: Must use `context.out_b`
3. **Not freeing resources**: Implement `free` method
4. **Wrong command types**: Match Lua argument types
5. **CPU overload**: Monitor CPU usage on norns
6. **Not using doneAction**: Synths may accumulate
7. **Forgetting .add**: SynthDefs won't be available

## SuperCollider Tips for Norns

### CPU Efficiency
- Use efficient UGens (Saw vs LFSaw)
- Limit polyphony appropriately
- Use doneAction to free synths
- Monitor CPU in norns SYSTEM > STATS

### Audio Quality
- Consider sample rate (48kHz on norns)
- Use appropriate envelope times
- Filter aliasing (use .ar instead of .kr where needed)
- Test with headphones and speakers

### Debugging
- Use `postln()` to print to SuperCollider log
- Check maiden's SuperCollider output tab
- Test SynthDefs individually in SuperCollider
- Use simpler synthesis first, then add complexity

## Installation

Engines are installed in:
```
dust/code/myengine/
└── Engine_MyEngine.sc
```

Or in the same directory as the script that uses them.

## Documentation

Document in comments at top of file:
- Engine name and purpose
- Available commands and parameters
- Example usage
- Credits and version
