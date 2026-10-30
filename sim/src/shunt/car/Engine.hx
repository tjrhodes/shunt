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

	/** The engine pulls forwards with the accelerator, or backwards (with the brake pedal) in reverse. */
	static function enginePull(car:Car, input:CarInput):Float {
		if (wantsToReverse(car, input)) {
			return -pullInGear(car, Tuning.reversePull, input.brake, -car.forwardSpeed(), Tuning.reverseTopSpeed);
		}
		return pullInGear(car, Tuning.enginePull, car.throttle, car.forwardSpeed(), Tuning.topSpeed);
	}

	/**
	 * The pull in one direction: the engine's full pull, times how far the
	 * pedal is down, fading as the car nears its top speed that way. A
	 * damaged car has less pull and a lower top speed (SPEC.md §4b).
	 */
	static function pullInGear(car:Car, fullPull:Float, pedal:Float, speedThatWay:Float, topSpeed:Float):Float {
		var stillWorking = Damage.speedShare(car);
		return fullPull * stillWorking * pedal * pullLeftAt(speedThatWay, topSpeed * stillWorking);
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
	 * Brakes, engine braking (the accelerator up, unless it is driving the car
	 * in reverse) and rolling resistance only
	 * ever slow the car down: they push against the way it is rolling, but
	 * never hard enough to send it back the other way within one tick.
	 */
	static function slowingDown(car:Car, input:CarInput):Float {
		var isReversing = wantsToReverse(car, input);
		var braking = isReversing ? 0 : input.brake * Tuning.brakeForce;
		var engineHoldingBack = isReversing ? 0 : Tuning.engineBraking * (1 - car.throttle);
		var rollingSpeed = car.forwardSpeed();
		var mostThatStopsWithoutReversing = Tuning.mass * Math.abs(rollingSpeed) / Tick.seconds;
		return -signOf(rollingSpeed) * Math.min(braking + engineHoldingBack + Tuning.rollingResistance, mostThatStopsWithoutReversing);
	}

	/** The air pushes back against the way the car is going, harder and harder with speed (speed squared). */
	static function airPushingBack(car:Car):Push {
		return Push.straight(car.velocity * (-Tuning.airDrag * car.speed()));
	}
}
