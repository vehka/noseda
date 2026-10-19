// Diagnostic capture at the engine stereo bus, upstream of the physical DAC.
// Invoke while the Lua script holds its note/transport; label via ~acceptLabel.
fork {
    var server = Crone.server;
    var buffer, values, left, right, frames, hz, sum, peak, crossings;
    var report, path;
    SynthDef(\noseda_accept_capture, {
        arg buf, bus;
        RecordBuf.ar(In.ar(bus, 2), buf, loop: 0, doneAction: 2);
    }).send(server);
    server.sync;
    frames = 96000;
    buffer = Buffer.alloc(server, frames, 2);
    server.sync;
    Synth(\noseda_accept_capture, [\buf, buffer, \bus, Crone.context.out_b],
        target: Crone.context.xg, addAction: \addToTail);
    2.2.wait;
    buffer.getToFloatArray(action: { |data| values = data });
    while { values.isNil } { 0.05.wait };
    left = values.clump(2).collect(_[0]);
    right = values.clump(2).collect(_[1]);
    // Analyze the middle one second, excluding gate/record startup edges.
    left = left.copyRange(24000,71999);
    right = right.copyRange(24000,71999);
    sum = left.squared.sum / left.size;
    peak = left.abs.maxItem;
    crossings = 0;
    (left.size-1).do { |i| if ((left[i] <= 0) and: {left[i+1] > 0}) { crossings = crossings+1 } };
    hz = crossings * server.sampleRate / left.size;
    report = ["AUDIO", ~acceptLabel, "engine", Crone.engine.class.name,
        "rmsL", sum.sqrt, "rmsR", (right.squared.sum/right.size).sqrt,
        "peakL", peak, "positiveCrossingsHz", hz,
        "stereoMaxDifference", (left-right).abs.maxItem];
    report.postln;
    path = "/home/we/dust/data/noseda_acceptance/audio-" ++ ~acceptLabel ++ ".txt";
    File.use(path, "w", { |f| f.write(report.asCompileString) });
    buffer.free;
    SynthDef.removeAt(\noseda_accept_capture);
    server.sendMsg(\d_free, \noseda_accept_capture);
};
