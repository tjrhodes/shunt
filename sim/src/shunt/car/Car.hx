package shunt.car;

import shunt.car.Damage.DamageZones;
import shunt.maths.Vector;

/**
 * Everything about one car at one moment: where it is, how it is moving, and
 * where its driver's hands and feet have got to.
 *
 * It is plain data with no behaviour, so it can be copied, compared, saved
 * and sent over the network as it is. What a car *does* lives in the classes
 * that work on it (`CarFrame`, `Controls`, `Tyres`, `Engine`, `CarMotion`),
 * brought in with `using`, so code still reads `car.forwardSpeed()`.
 */
typedef Car = {
	/** Where the car's centre of mass is, in metres. */
	var position:Vector;

	/** Which way the nose points, in radians, anticlockwise from east. */
	var heading:Float;

	/** How fast and which way the car is moving, in metres per second. */
	var velocity:Vector;

	/** How fast the car is turning, in radians per second, anticlockwise. */
	var spin:Float;

	/** How far the front wheels are turned to the right, in radians (they follow the driver's hands smoothly). */
	var wheelAngle:Float;

	/** How far down the accelerator is, 0 to 1 (it follows the driver's foot smoothly). */
	var throttle:Float;

	/** How far the car's weight leans to the right-hand tyres, in g (it rolls over a moment after a turn: `WeightShift`). */
	var sidewaysLoad:Float;

	/** How battered each side is (SPEC.md §4b). */
	var damage:DamageZones;
}

/** Making cars, and copying them. */
class Cars {
	/** A car standing still at a place, facing a direction, wheels straight. */
	public static function parkedAt(position:Vector, heading:Float):Car {
		return {
			position: position,
			heading: heading,
			velocity: Vector.nothing(),
			spin: 0,
			wheelAngle: 0,
			throttle: 0,
			sidewaysLoad: 0,
			damage: Damage.none
		};
	}

	/**
	 * A separate car exactly like this one. A shallow copy is enough because
	 * every field is a number, or an arrow or damage, which never change.
	 */
	public static function copyOf(car:Car):Car {
		return Reflect.copy(car);
	}
}
