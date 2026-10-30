package shunt.car;

import shunt.car.CarTuning as Tuning;
import shunt.maths.Numbers.keepBetween;
import shunt.maths.Numbers.partWay;
import shunt.maths.Numbers.stepTowards;

using shunt.car.CarFrame;

/**
 * The driver's hands and feet. A key is either down or up, but a steering
 * wheel and an accelerator take a moment to move, so the car's wheel and
 * pedal follow the input at their own pace. That turns a tap of a key into
 * a smooth, small correction.
 */
class Controls {
	/** Moves the front wheels and the accelerator one tick's worth towards what the driver asks. */
	public static function followTheDriver(car:Car, input:CarInput) {
		var wheelMovePerTick = Tuning.wheelTurnRate * Tick.seconds;
		var pedalMovePerTick = Tuning.throttleRate * Tick.seconds;
		car.wheelAngle = stepTowards(car.wheelAngle, wheelAngleAskedFor(car, input), wheelMovePerTick);
		car.throttle = stepTowards(car.throttle, input.throttle, pedalMovePerTick);
	}

	/**
	 * Where the driver wants the wheels: their steering times the most the
	 * wheels may turn now. A bent front also pulls the wheels to one side,
	 * which the driver has to hold against (SPEC.md §4b).
	 */
	static function wheelAngleAskedFor(car:Car, input:CarInput):Float {
		return input.steer * mostSteeringNow(car) + Damage.steeringPull(car);
	}

	/**
	 * The most the front wheels may turn at the car's speed: full lock when
	 * slow, much less when fast. A badly damaged front takes some away.
	 */
	public static function mostSteeringNow(car:Car):Float {
		var shareOfTopSpeed = keepBetween(car.speed() / Tuning.topSpeed, 0, 1);
		var mostWhenNew = partWay(Tuning.mostSteeringWhenSlow, Tuning.mostSteeringAtTopSpeed, shareOfTopSpeed);
		return mostWhenNew * Damage.steeringShare(car);
	}
}
