package sound;

import js.html.audio.AudioContext;
import js.html.audio.AudioNode;
import js.html.audio.BiquadFilterNode;
import js.html.audio.GainNode;
import js.html.audio.OscillatorNode;
import shunt.car.Car;
import shunt.car.CarTuning;
import sound.SoundTuning as Tuning;

using shunt.car.CarFrame;

/**
 * One car's engine: two buzzing notes an octave apart, through a filter
 * that opens up with the throttle. The note climbs with speed through each
 * gear, drops when the gear changes, and climbs again.
 */
class EngineVoice {
	final context:AudioContext;
	final low:OscillatorNode;
	final high:OscillatorNode;
	final tone:BiquadFilterNode;
	final volume:GainNode;

	public function new(context:AudioContext, output:AudioNode) {
		this.context = context;
		low = buzz(SAWTOOTH);
		high = buzz(SQUARE);
		tone = context.createBiquadFilter();
		tone.type = LOWPASS;
		volume = context.createGain();
		volume.gain.value = 0;
		low.connect(tone);
		high.connect(tone);
		tone.connect(volume).connect(output);
	}

	/** Sounds the car as it is now, at a loudness (the player's engine is louder). */
	public function follow(car:Car, loudness:Float) {
		var now = context.currentTime;
		var note = noteAt(car.speed());
		low.frequency.setTargetAtTime(note, now, Tuning.followTime);
		high.frequency.setTargetAtTime(note * 2.01, now, Tuning.followTime);
		tone.frequency.setTargetAtTime(Tuning.engineDull + Tuning.engineOpensUpBy * car.throttle, now, Tuning.followTime);
		volume.gain.setTargetAtTime(loudness * (0.5 + 0.5 * car.throttle), now, Tuning.followTime);
	}

	/** The engine dies away (the race has stopped). */
	public function stop() {
		volume.gain.setTargetAtTime(0, context.currentTime, Tuning.followTime);
	}

	/** The engine's note at a speed: which gear it would be in, and how far through that gear. */
	static function noteAt(speed:Float):Float {
		var speedPerGear = CarTuning.topSpeed / Tuning.gears;
		var gear = Math.min(Tuning.gears - 1, Math.floor(speed / speedPerGear));
		var throughTheGear = Math.min(1, (speed - gear * speedPerGear) / speedPerGear);
		return Tuning.idleNote + gear * Tuning.gearStep + throughTheGear * Tuning.climbInAGear;
	}

	function buzz(shape:js.html.audio.OscillatorType):OscillatorNode {
		var note = context.createOscillator();
		note.type = shape;
		note.frequency.value = Tuning.idleNote;
		note.start();
		return note;
	}
}
