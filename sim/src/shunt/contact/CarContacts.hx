package shunt.contact;

import shunt.car.Car;
import shunt.car.CarTuning as Tuning;
import shunt.maths.Numbers.signOf;
import shunt.maths.Vector;

using shunt.car.CarFrame;

/** A direction two cars could be pushed apart along, and how far they overlap along it. */
typedef OverlapAlong = {
	final direction:Vector;
	final overlap:Float;
}

/**
 * Where two cars touch, and which way to push them apart.
 *
 * Each car is a box. Two boxes are apart if a line can be drawn between
 * them, and that line always runs along one of their four sides. So look
 * along each side's direction: if the boxes' shadows on it don't overlap,
 * the cars are apart. If they overlap along all four, the cars touch, and
 * the direction they overlap least along is the shortest way out.
 *
 * (It used to look only for a corner of one car inside the other. Two cars
 * lying across each other like a plus sign, or one nose-first into the
 * other's side, have no corner inside, so they drove through each other.)
 */
class CarContacts {
	static inline final halfLength = Tuning.length / 2;
	static inline final halfWidth = Tuning.width / 2;

	/** Where `first` and `second` overlap, with the way to push `first` off `second`; null if apart. */
	public static function deepestBetween(first:Car, second:Car):Null<Contact> {
		if (first.position.distanceTo(second.position) > 2 * CarShape.reach) return null;
		var shallowest:Null<OverlapAlong> = null;
		for (direction in sidesOf(first).concat(sidesOf(second))) {
			var overlap = overlapAlong(first, second, direction);
			if (overlap <= 0) return null;
			if (shallowest == null || overlap < shallowest.overlap) shallowest = {direction: direction, overlap: overlap};
		}
		var away = shallowest.direction * signOf((first.position - second.position).along(shallowest.direction));
		return {point: whereTheyMeet(first, second, away), pushFirstAway: away, overlap: shallowest.overlap};
	}

	/** The directions a car's sides run in: along it, and across it. */
	static function sidesOf(car:Car):Array<Vector> {
		return [car.noseDirection(), car.leftDirection()];
	}

	/** How far the two cars' shadows on a line overlap (negative: a gap between them). */
	static function overlapAlong(first:Car, second:Car, direction:Vector):Float {
		var apart = Math.abs((first.position - second.position).along(direction));
		return halfShadow(first, direction) + halfShadow(second, direction) - apart;
	}

	/** Half the length of a car's shadow on a line through its middle. */
	static function halfShadow(car:Car, direction:Vector):Float {
		return halfLength * Math.abs(car.noseDirection().along(direction)) + halfWidth * Math.abs(car.leftDirection().along(direction));
	}

	/** The middle of where they meet: half way between the part of each that has gone furthest into the other. */
	static function whereTheyMeet(first:Car, second:Car, pushFirstAway:Vector):Vector {
		return (furthestIn(first, pushFirstAway * -1) + furthestIn(second, pushFirstAway)) * 0.5;
	}

	/** The part of a car furthest along a direction: its leading corner, or the middle of its leading side when that side faces square on. */
	static function furthestIn(car:Car, direction:Vector):Vector {
		var corners = CarShape.corners(car);
		corners.sort((one, other) -> Reflect.compare(other.along(direction), one.along(direction)));
		var isSquareOn = corners[0].along(direction) - corners[1].along(direction) < 0.05;
		return isSquareOn ? (corners[0] + corners[1]) * 0.5 : corners[0];
	}
}
