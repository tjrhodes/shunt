package sound;

import feel.Slide;
import js.Browser;
import js.html.audio.AudioBuffer;
import js.html.audio.AudioContext;
import js.html.audio.GainNode;
import shunt.race.Race;
import shunt.race.RaceEvent;
import sound.SoundTuning as Tuning;

/**
 * Everything the game sounds like, made as it plays (no sound files): an
 * engine and tyres for every car, and the hits and start lights. Browsers
 * only allow sound after the player presses something, so it all starts
 * at the first press of Start.
 */
class Sound {
	static inline final rememberedAs = "shunt.soundOn";

	/** Whether sound is on: the player's choice, remembered between visits where the browser allows. */
	public var isOn(default, null):Bool;

	var context:Null<AudioContext> = null;
	var master:GainNode;
	var engines:Array<EngineVoice> = [];
	var squeals:Array<SquealVoice> = [];
	var oneShots:OneShots;

	public function new() {
		isOn = rememberedChoice();
	}

	/** Starts sound (the first time, for this many cars) or carries it on: call it from a press. */
	public function wake(cars:Int) {
		if (context == null) build(cars);
		context.resume();
	}

	/** Pauses every sound (paused game, results). */
	public function rest() {
		if (context != null) context.suspend();
	}

	/** Turns sound off, or back on, and remembers the choice. */
	public function toggle() {
		isOn = !isOn;
		if (master != null) master.gain.value = isOn ? Tuning.overall : 0;
		try Browser.window.localStorage.setItem(rememberedAs, isOn ? "yes" : "no") catch (_) {}
	}

	/** Every car's engine and tyres, as they are now. */
	public function follow(race:Race) {
		if (context == null) return;
		for (seat in 0...engines.length) {
			var car = race.racer(seat).car;
			engines[seat].follow(car, seat == 0 ? Tuning.playerEngine : Tuning.otherEngines);
			squeals[seat].follow(Slide.strength(car), seat == 0 ? Tuning.playerSqueal : Tuning.otherSqueals);
		}
	}

	/** Something that happened in the race, if it makes a sound. */
	public function hear(event:RaceEvent) {
		if (context == null) return;
		switch event.kind {
			case LightOn: oneShots.beep(false);
			case Green: oneShots.beep(true);
			case CarHit: oneShots.hit(loudnessOf(event));
			case WallHit: oneShots.scrape(loudnessOf(event));
			case _:
		}
	}

	/** A hit is louder the harder it was, and louder still if it was the player's car. */
	static function loudnessOf(hit:RaceEvent):Float {
		var isThePlayers = hit.racer == 0 || hit.other == 0;
		return (isThePlayers ? Tuning.playerHit : Tuning.otherHits) * Math.min(1, hit.strength / Tuning.loudestHitFrom);
	}

	/** The sound system: a master volume, and the voices of every car. */
	function build(cars:Int) {
		context = new AudioContext();
		master = context.createGain();
		master.gain.value = isOn ? Tuning.overall : 0;
		master.connect(context.destination);
		var hiss = hissOf(context);
		engines = [for (_ in 0...cars) new EngineVoice(context, master)];
		squeals = [for (_ in 0...cars) new SquealVoice(context, master, hiss)];
		oneShots = new OneShots(context, master, hiss);
	}

	/** A second of hiss (white noise), the raw stuff of squeals and crunches. */
	static function hissOf(context:AudioContext):AudioBuffer {
		var length = Std.int(context.sampleRate);
		var hiss = context.createBuffer(1, length, context.sampleRate);
		var samples = hiss.getChannelData(0);
		for (index in 0...length) samples[index] = Math.random() * 2 - 1;
		return hiss;
	}

	/** The choice remembered from a last visit, or on if there is none (or the browser keeps nothing). */
	static function rememberedChoice():Bool {
		try return Browser.window.localStorage.getItem(rememberedAs) != "no" catch (_) return true;
	}
}
