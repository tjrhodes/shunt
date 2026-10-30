package shunt.car;

import shunt.car.CarTuning as Tuning;
import shunt.maths.Numbers.signOf;

using shunt.car.CarFrame;

/**
 * Everything that pushes the car along its length: the engine, reverse,
 * the brakes, the tyres' rolling resistance, and the air.
 */
class Engine {
	/** The engine's pull, the brakes and rolling resistance along the car, and the air against it. */
	public static function engineBrakesAndAir(car:Car, input:CarInput):Push {
		var pullAlongTheCar = enginePull(car, input) + slowingDown(car, input);
		var alongTheCar = Push.straight(car.noseDirection() * pullAlongTheCar);
		return alongTheCar.plus(airPushingBack(car));
	}

	/**
	 * Holding the brake when (nearly) stopped, with the accelerator up, means
	 * "go backwards", as in most racing games.
	 */
	static function wantsToReverse(car:Car, input:CarInput):Bool {
		return input.brake > 0 && input.throttle == 0 && car.forwardSpeed() < Tuning.stoppedBelow;
	}

	/** The engine pulls forwards with the accelerator, or backwards in reverse. */
	static function enginePull(car:Car, input:CarInput):Float {
		if (wantsToReverse(car, input)) {
			return -Tuning.reversePull * input.brake * pullLeftAt(-car.forwardSpeed(), Tuning.reverseTopSpeed);
		}
		return Tuning.enginePull * car.throttle * pullLeftAt(car.forwardSpeed(), Tuning.topSpeed);
	}

	/**
	 * The engine pulls hardest from a standstill and less and less as the car
	 * nears its top speed, where it can pull no more. Going the other way it
	 * pulls harder still, so the accelerator stops a reversing car quickly.
	 */
	static function pullLeftAt(speed:Float, topSpeed:Float):Float {
		return Math.max(0, 1 - speed / topSpeed);
	}

	/**
	 * Brakes and rolling resistance only ever slow the car down: they push
	 * against the way it is rolling, but never hard enough to send it back
	 * the other way within one tick.
	 */
	static function slowingDown(car:Car, input:CarInput):Float {
		var braking = wantsToReverse(car, input) ? 0 : input.brake * Tuning.brakeForce;
		var rollingSpeed = car.forwardSpeed();
		var mostThatStopsWithoutReversing = Tuning.mass * Math.abs(rollingSpeed) / Tick.seconds;
		return -signOf(rollingSpeed) * Math.min(braking + Tuning.rollingResistance, mostThatStopsWithoutReversing);
	}

	/** The air pushes back against the way the car is going, harder and harder with speed (speed squared). */
	static function airPushingBack(car:Car):Push {
		return Push.straight(car.velocity * (-Tuning.airDrag * car.speed()));
	}
}
