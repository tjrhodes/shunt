package input;

import shunt.maths.Numbers.partWay;

/**
 * Steering from something that is only on or off, like a key or a finger.
 * It starts gentle and builds the longer it is held, up to full: a tap is a
 * small correction, holding turns the car in properly. (A gamepad stick
 * doesn't need this: it is already as gradual as the thumb on it.)
 *
 * Going straight from one side to the other keeps what has built up, even
 * with a moment's gap between the keys: that is a flick (Tom, 1 Nov), and
 * starting the new side gentle again would let the car's weight settle
 * before the steering got there. Letting go for longer starts afresh.
 */
class SteeringRamp {
	/** The share of full steering the moment a key goes down... */
	static inline final shareAtFirst = 0.3;

	/** ...building to full after it has been held this many seconds. */
	static inline final secondsToFull = 0.6;

	/** Let go for less than this and pressed again, it carries on from where it was. */
	static inline final switchingGap = 0.15;

	var heldSince = -1.0;
	var heldWay = 0.0;
	var letGoAt = -1.0;
	var builtBeforeLettingGo = 0.0;

	public function new() {}

	/**
	 * The steering at a moment (seconds, on any clock that keeps going) for
	 * the way held then (-1 left, 1 right, 0 nothing). Asking more than once
	 * in a moment changes nothing.
	 */
	public function steering(wayHeld:Float, now:Float):Float {
		if (wayHeld == 0) {
			letGo(now);
			return 0;
		}
		if (heldSince < 0) heldSince = isASwitch(now) ? now - builtBeforeLettingGo : now;
		heldWay = wayHeld;
		return wayHeld * partWay(shareAtFirst, 1, Math.min(1, (now - heldSince) / secondsToFull));
	}

	/** Remembers how far it had built, the moment it is let go. */
	function letGo(now:Float) {
		if (heldSince < 0) return;
		builtBeforeLettingGo = now - heldSince;
		letGoAt = now;
		heldSince = -1;
	}

	function isASwitch(now:Float):Bool {
		return letGoAt >= 0 && now - letGoAt < switchingGap;
	}
}
