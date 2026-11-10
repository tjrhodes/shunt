package shunt.car;

import shunt.maths.Numbers.keepBetween;

/**
 * What a driver asks of their car in one tick: how hard on the accelerator
 * and the brake, which way to steer, and whether to be put back on the
 * track. Keyboards, gamepads, touch, AI drivers and (later) the network all
 * make one of these; the car can't tell which (SPEC.md §3).
 */
typedef CarInput = {
	/** 0 (off) to 1 (floored). */
	final throttle:Float;

	/** 0 (off) to 1 (full); held when stopped, it reverses. */
	final brake:Float;

	/** -1 (full left) to 1 (full right). */
	final steer:Float;

	/** Asks to be put back on the track (used from the track step on). */
	final recover:Bool;
}

/** Ready-made inputs, and tidying of inputs from outside. */
class CarInputs {
	/** Hands and feet off. */
	public static final nothingPressed:CarInput = {
		throttle: 0,
		brake: 0,
		steer: 0,
		recover: false
	};

	/**
	 * The same input, with every number brought back into its range. An input
	 * can come from anywhere, even a misbehaving network client, so the car
	 * never trusts one as it arrives.
	 */
	public static function tidied(input:CarInput):CarInput {
		return {
			throttle: keepBetween(aNumber(input?.throttle), 0, 1),
			brake: keepBetween(aNumber(input?.brake), 0, 1),
			steer: keepBetween(aNumber(input?.steer), -1, 1),
			recover: input?.recover == true
		};
	}

	/** Something that should be a number: itself if it is a real one, otherwise 0 (so nothing strange gets into the physics). */
	static function aNumber(thing:Dynamic):Float {
		return Std.isOfType(thing, Float) && Math.isFinite(thing) ? thing : 0;
	}
}
