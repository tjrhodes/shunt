package input;

import js.Browser;
import shunt.maths.Numbers.partWay;

/**
 * Steering from something that is only on or off, like a key or a finger.
 * It starts gentle and builds the longer it is held, up to full: a tap is a
 * small correction, holding turns the car in properly. (A gamepad stick
 * doesn't need this: it is already as gradual as the thumb on it.)
 */
class SteeringRamp {
	/** The share of full steering the moment a key goes down... */
	static inline final shareAtFirst = 0.3;

	/** ...building to full after it has been held this many seconds. */
	static inline final secondsToFull = 0.6;

	var heldSince = -1.0;
	var heldWay = 0.0;

	public function new() {}

	/**
	 * The steering for the way held now (-1 left, 1 right, 0 nothing). It
	 * goes by the clock, so asking more than once in a moment changes nothing;
	 * letting go, or switching sides, starts the build again.
	 */
	public function steering(wayHeld:Float):Float {
		if (wayHeld == 0) {
			heldSince = -1;
			return 0;
		}
		var now = Browser.window.performance.now() / 1000;
		if (heldSince < 0 || wayHeld != heldWay) {
			heldSince = now;
			heldWay = wayHeld;
		}
		return wayHeld * partWay(shareAtFirst, 1, Math.min(1, (now - heldSince) / secondsToFull));
	}
}
