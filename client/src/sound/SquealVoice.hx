package sound;

import js.html.audio.AudioBuffer;
import js.html.audio.AudioContext;
import js.html.audio.AudioNode;
import js.html.audio.GainNode;
import sound.SoundTuning as Tuning;

/**
 * One car's tyres squealing: hiss narrowed down to a whine, louder the
 * harder the car slides (the same slide the skid marks show).
 */
class SquealVoice {
	final context:AudioContext;
	final volume:GainNode;

	public function new(context:AudioContext, output:AudioNode, hiss:AudioBuffer) {
		this.context = context;
		var source = context.createBufferSource();
		source.buffer = hiss;
		source.loop = true;
		var whine = context.createBiquadFilter();
		whine.type = BANDPASS;
		whine.frequency.value = Tuning.squealNote;
		whine.Q.value = Tuning.squealPurity;
		volume = context.createGain();
		volume.gain.value = 0;
		source.connect(whine).connect(volume).connect(output);
		source.start();
	}

	/** Squeals as hard as the car is sliding (0 to 1), at a loudness. */
	public function follow(slide:Float, loudness:Float) {
		volume.gain.setTargetAtTime(slide * loudness, context.currentTime, Tuning.followTime);
	}
}
