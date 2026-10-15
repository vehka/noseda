Engine_NoSEDATone : CroneEngine {
    var synth;

    alloc {
        SynthDef(\noseda_tone_voice, {
            arg out = 0, hz = 220, amp = 0.15, gate = 0;
            var env = EnvGen.kr(Env.asr(0.01, 1, 0.05), gate);
            var signal = SinOsc.ar(hz.lag(0.02)) * amp.lag(0.02) * env;
            Out.ar(out, [signal, signal]);
        }).send(context.server);
        context.server.sync;

        synth = Synth(\noseda_tone_voice,
            [\out, context.out_b], target: context.xg);

        this.addCommand(\hz, "f", { arg msg;
            synth.set(\hz, msg[1].clip(40, 4000));
        });
        this.addCommand(\amp, "f", { arg msg;
            synth.set(\amp, msg[1].clip(0, 0.5));
        });
        this.addCommand(\gate, "i", { arg msg;
            synth.set(\gate, msg[1].clip(0, 1));
        });
    }

    free {
        if(synth.notNil) {
            synth.free;
            synth = nil;
        };
    }
}
