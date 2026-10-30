package shunt.car;

import shunt.car.CarTuning as Tuning;
import shunt.maths.Numbers.keepBetween;
import shunt.maths.Vector;

using shunt.car.CarFrame;

/**
 * A helping hand, as arcade racers have (SPEC.md §4). Real cars want a
 * driver's quick hands to stop a slide turning into a spin; on a keyboard
 * that is too much to ask. So the car's turning is gently drawn towards
 * what its front wheels ask for: turning the wheels turns the car, a small
 * correction stays small, and countersteering catches a slide.
 */
class Steadying {
	/** A twist that draws the car's spin towards the spin its wheels ask for, at the steadying rate. */
	public static function steadyingHand(car:Car):Push {
		var spinToLoseOrGain = car.spin - spinTheWheelsAskFor(car);
		var twist = -Tuning.steadying * Tuning.turningInertia * spinToLoseOrGain;
		return new Push(Vector.nothing(), twist * Tyres.tyreModelShare(car));
	}

	/**
	 * The spin the front wheels ask for: as if they rolled without sliding,
	 * but never more than the tyres' grip could hold at this speed.
	 */
	static function spinTheWheelsAskFor(car:Car):Float {
		var mostTheGripAllows = Math.min(Tuning.frontGrip, Tuning.rearGrip) * Tuning.gravity / Math.max(1, car.speed());
		return keepBetween(CarMotion.spinOfRollingWheels(car), -mostTheGripAllows, mostTheGripAllows);
	}
}
