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
	 * wheels may turn at this speed (full lock when slow, much less when fast).
	 */
	static function wheelAngleAskedFor(car:Car, input:CarInput):Float {
		var shareOfTopSpeed = keepBetween(car.speed() / Tuning.topSpeed, 0, 1);
		var mostSteering = partWay(Tuning.mostSteeringWhenSlow, Tuning.mostSteeringAtTopSpeed, shareOfTopSpeed);
		return input.steer * mostSteering;
	}
}
