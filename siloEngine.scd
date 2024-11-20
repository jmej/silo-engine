
// plot the buffer
//~bufferInputFile.plot; // we can visualize this buffer
// check the buffer length
//~bufferInputFile.numFrames/~bufferInputFile.sampleRate; // length in seconds

(
//start server
s.waitForBoot({

var w, startButton, sliders;
var node, cmdPeriodFunc;
var params, specs;

SynthDef("silo", {
	arg bufnum=0, rate=1, dur=0.1, pos=0, jitter = 1, spray=0, grains=10, vol=0;
	var snd;
	var newGrain=Impulse.kr(grains,1-spray)+Dust.kr(grains,spray);

    snd=GrainBuf.ar(
		numChannels:2,
		trigger:newGrain,
		dur: dur, //in seconds
		sndbuf:bufnum,
		rate:rate,
		pos:pos+LFNoise0.kr(3).range(-0.5, 0.5),
		mul: vol
	).poll;

	snd = FreeVerb.ar(snd);
	Out.ar(0,snd);
}).add;

	params = ["rate", "dur", "pos", "jitter", "spray", "grains", "vol"];
specs = [
    ControlSpec(0.1, 8, \lin, 0.001, 0, \rate),
    ControlSpec(0, 1, \lin,0.001,0, \dur),
    ControlSpec(0, 1, \lin,0.001,0, \pos),
    ControlSpec(1, 10, \lin,0.01,0, \jitter),
	ControlSpec(0, 1, \lin,0.01,0, \spray),
	ControlSpec(10, 50, \lin,1,0, \grains),
	ControlSpec(0.0001, 2, \exp, 0, 0.3, \vol), // db spec acts weird, so use self made one
/*    ControlSpec(-1, 1, \lin, 0, 0, \pan),

    ControlSpec(0, 1, \lin, 0, 0.3, \width),*/
];

~bufferInputFile=Buffer.readChannel(s,thisProcess.nowExecutingPath.dirname++"/weather.wav",channels:0);

x=Synth("silo", [\bufnum, \rate, \dur, \pos, \jitter, \spray, \grains, \vol, ~bufferInputFile]); // will start playing

// make the window
w = Window("silo-engine", Rect(20, 400, 440, 180));
w.front; // make window visible and front window.
w.view.decorator = FlowLayout(w.view.bounds);
w.view.decorator.gap=2@2;

// add a button to start and stop the sound.
startButton = Button(w, 75 @ 20);
startButton.states = [
    ["Start", Color.black, Color.green(0.7)],
    ["Stop", Color.white, Color.red(0.7)]
];
startButton.action = {|view|
        var args;
        if (view.value == 1) {
            // start sound
            params.do { |param, i|
                args = args.add(param);
                args = args.add(sliders[i].value)
            };
            node = x;
			node.set(\vol, 1);
        } {
            // set gate to zero to cause envelope to release
			node.set(\vol, 0); node = nil;
        };
};

// create controls for all parameters
w.view.decorator.nextLine;
sliders = params.collect { |param, i|
    EZSlider(w, 430 @ 20, param, specs[i], {|ez| node.set( param, ez.value )})
        .setColors(Color.grey,Color.white, Color.grey(0.7),Color.grey, Color.white, Color.yellow);
};
// set start button to zero upon a cmd-period
cmdPeriodFunc = { startButton.value = 0; };
CmdPeriod.add(cmdPeriodFunc);

// stop the sound when window closes and remove cmdPeriodFunc.
w.onClose = {
    node.free; node = nil;
    CmdPeriod.remove(cmdPeriodFunc);
};

})
)

x.free();






/*
(
w = Window.new.front;
r = EZSlider( w,         // parent
              390@20,    // bounds
              " rate ",  // label
              \rate,     // controlSpec - rate seems to give me a built in map of 0.13-8
	{ |ez| (x.set(\rate, ez.value))} // action
);

g.setColors(Color.grey,Color.white)
);*/







// from the docs
(
var winenv;

b = Buffer.read(s, Platform.resourceDir +/+ "sounds/a11wlk01-44_1.aiff");
// a custom envelope
winenv = Env([0, 1, 0], [0.5, 0.5], [8, -8]);
z = Buffer.sendCollection(s, winenv.discretize, 1);

SynthDef(\buf_grain_test, { |out, gate = 1, amp = 1, sndbuf, envbuf|
    var pan, env, freqdev;
    // use mouse x to control panning
    pan = MouseX.kr(-1, 1);
    env = EnvGen.kr(
        Env([0, 1, 0], [1, 1], \sin, 1),
        gate,
        levelScale: amp,
        doneAction: Done.freeSelf);
    Out.ar(out,
        GrainBuf.ar(2, Impulse.kr(10), 0.1, sndbuf, LFNoise1.kr.range(0.5, 2),
            LFNoise2.kr(0.1).range(0, 1), 2, pan, envbuf) * env)
}).add;
)

// use built-in env
x = Synth(\buf_grain_test, [\sndbuf, b, \envbuf, -1])

// switch to the custom env
x.set(\envbuf, z)
x.set(\envbuf, -1);

x.set(\gate, 0);