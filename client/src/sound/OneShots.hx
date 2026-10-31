package sound;

import js.html.audio.AudioBuffer;
import js.html.audio.AudioContext;
import js.html.audio.AudioNode;
import js.html.audio.OscillatorType;
import sound.SoundTuning as Tuning;

/**
 * Sounds that happen once and die away: hits (a thump and a crunch of
 * hiss), wall scrapes (shorter and brighter), and the start lights' beeps.
 */
class OneShots {
	final context:AudioContext;
	final output:AudioNode;
	final hiss:AudioBuffer;

	public function new(context:AudioContext, output:AudioNode, hiss:AudioBuffer) {
		this.context = context;
		this.output = output;
		this.hiss = hiss;
	}

	/** A car hit: a low thump and a crunch, at a loudness. */
	public function hit(loudness:Float) {
		note(SINE, Tuning.thumpNote, loudness, Tuning.hitRings);
		crunch(900, loudness, Tuning.hitRings);
	}

	/** A wall scrape: a shorter, brighter crunch. */
	public function scrape(loudness:Float) {
		crunch(2400, loudness * 0.6, Tuning.scrapeRings);
	}

	/** A red light's beep, or the green's higher, longer one. */
	public function beep(isGreen:Bool) {
		var pitch = isGreen ? Tuning.greenBeep : Tuning.redBeep;
		note(SINE, pitch, Tuning.beepLoudness, isGreen ? Tuning.greenBeepLasts : Tuning.redBeepLasts);
	}

	/** A note that starts at a loudness and dies away over some seconds. */
	function note(shape:OscillatorType, pitch:Float, loudness:Float, seconds:Float) {
		var sound = context.createOscillator();
		sound.type = shape;
		sound.frequency.value = pitch;
		sound.connect(dyingAway(loudness, seconds));
		sound.start();
		sound.stop(context.currentTime + seconds);
	}

	/** A burst of hiss, filtered to dull it (a crunch) or brighten it (a scrape), dying away. */
	function crunch(brightness:Float, loudness:Float, seconds:Float) {
		var burst = context.createBufferSource();
		burst.buffer = hiss;
		var tone = context.createBiquadFilter();
		tone.type = LOWPASS;
		tone.frequency.value = brightness;
		burst.connect(tone).connect(dyingAway(loudness, seconds));
		burst.start(0, Math.random() * 0.5);
		burst.stop(context.currentTime + seconds);
	}

	/** A volume that starts at a loudness and falls away to silence over some seconds; it leads to the output. */
	function dyingAway(loudness:Float, seconds:Float):AudioNode {
		var volume = context.createGain();
		var now = context.currentTime;
		volume.gain.setValueAtTime(loudness, now);
		volume.gain.exponentialRampToValueAtTime(0.0001, now + seconds);
		volume.connect(output);
		return volume;
	}
}
