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
		var hold = Tuning.steadying * (1 - Tuning.steadyingLostInAFlick * WeightShift.swing(car));
		var twist = -hold * Tuning.turningInertia * spinToLoseOrGain;
		return new Push(Vector.nothing(), twist * Tyres.tyreModelShare(car));
	}

	/**
	 * The spin the front wheels ask for: as if they rolled without sliding,
	 * but never more than the tyres' grip could hold at this speed, except
	 * near full lock (see `extraTurnAtFullLock`).
	 */
	static function spinTheWheelsAskFor(car:Car):Float {
		var gripHolds = Math.min(Tuning.frontGrip, Tuning.rearGrip) * Tuning.gravity / Math.max(1, car.speed());
		var mostAllowed = gripHolds * (1 + extraTurnAtFullLock(car));
		return keepBetween(CarMotion.spinOfRollingWheels(car), -mostAllowed, mostAllowed);
	}

	/**
	 * Held at (or near) full lock at speed, the car may turn a little more
	 * than its grip can hold, so it rotates into a slight drift: steering
	 * held down turns harder. Part lock gets nothing extra, and nor do slow
	 * cars: asking for more there scrubbed a held bend round into a doughnut.
	 */
	static function extraTurnAtFullLock(car:Car):Float {
		var shareOfLock = Math.abs(car.wheelAngle) / Controls.mostSteeringNow(car);
		var nearFullLock = keepBetween((shareOfLock - Tuning.extraTurnFromLock) / (1 - Tuning.extraTurnFromLock), 0, 1);
		var shareOfTopSpeed = keepBetween(car.speed() / Tuning.topSpeed, 0, 1);
		return Tuning.extraTurnAtFullLock * nearFullLock * shareOfTopSpeed;
	}
}
