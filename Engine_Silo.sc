// CroneEngine granular engine
Engine_Silo : CroneEngine {


    //var w, startButton, sliders; //for SC gui testing
	var node, cmdPeriodFunc;
	var params, specs;

    // inheritance from crone
    *new { arg context, doneCallback;
        ^super.new(context, doneCallback);
    }

    // alloc is where the SynthDef lives
    alloc {


		SynthDef("silo", {
			arg bufnum=0, rate=1, dur=0.1, pos=0, jitter = 1, spray=0, grains=10, vol=0.5;
			var snd;
			var newGrain=Impulse.kr(grains,1-spray)+Dust.kr(grains,spray);

			snd=GrainBuf.ar(
				numChannels:2,
				trigger:newGrain,
				dur: dur, //in seconds
				sndbuf:bufnum,
				rate:rate,
				pos:pos+LFNoise0.kr(3).range(-0.5, 0.5), //todo: replace 3 with something more dynamic
				mul: vol
			).poll;

			snd = FreeVerb.ar(snd);
			Out.ar(0,snd);
		}).add;

        context.server.sync;

		//create two instances of the synth
		// so two samples can be played simultaneously
        siloVoices = Array.fill(2,{arg i;
            Synth("silo",target:context.server);
        });


        // expose args to lua

		// a load function to load samples - is == int string where int is the sampler instance and string is the sample
        this.addCommand("sample","is", { arg msg;
            ("loading "++msg[2]).postln;
            Buffer.read(context.server,msg[2],action:{
                arg buffer;
                ("loaded "++msg[2]).postln;
                siloVoices[msg[1]-1].set(\bufnum,buffer);
            });
        });

        // setting the position
        this.addCommand("pos","if", { arg msg;
            synthSampler[msg[1]-1].set(
				\pos, msg[2],
            );
        });

        this.addCommand("rate","if", { arg msg;
            synthSampler[msg[1]-1].set(
                \rate,msg[2],
            );
        });


        this.addCommand("amp","if", { arg msg;
            synthSampler[msg[1]-1].set(
                \amp,msg[2],
            );
        });
    }


    free {
        //////// 5 ////////
        // free any variable we create
        // otherwise it won't ever stop!
        2.do({arg i; siloVoices[i].free});
    }
}
