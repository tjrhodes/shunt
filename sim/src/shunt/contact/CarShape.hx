package shunt.contact;

import shunt.car.Car;
import shunt.car.CarTuning as Tuning;
import shunt.maths.Numbers.signOf;
import shunt.maths.Vector;

using shunt.car.CarFrame;

/**
 * A car's shape for bumping into things: a box the car's length and width,
 * turned whichever way the car points.
 */
class CarShape {
	static inline final halfLength = Tuning.length / 2;
	static inline final halfWidth = Tuning.width / 2;

	/** How far the car's corners are from its middle: nothing further away can be touching it. */
	public static final reach = Math.sqrt(halfLength * halfLength + halfWidth * halfWidth);

	/** Where the car's four corners are. */
	public static function corners(car:Car):Array<Vector> {
		return [
			car.spotUnder(new Vector(halfLength, halfWidth)),
			car.spotUnder(new Vector(halfLength, -halfWidth)),
			car.spotUnder(new Vector(-halfLength, -halfWidth)),
			car.spotUnder(new Vector(-halfLength, halfWidth))
		];
	}

	/**
	 * Whether a point is inside the car (or within `margin` metres of its
	 * sides). If it is, the contact says how deep it is and which way the
	 * point would leave by the nearest side: that is the way to push the
	 * point's owner, so it is the contact's push for the point's side.
	 */
	public static function pointInside(car:Car, point:Vector, margin:Float):Null<Contact> {
		var local = car.inCarTerms(point - car.position);
		var lengthwaysRoom = halfLength + margin - Math.abs(local.x);
		var sidewaysRoom = halfWidth + margin - Math.abs(local.y);
		if (lengthwaysRoom <= 0 || sidewaysRoom <= 0) return null;
		var leavesByTheEnd = lengthwaysRoom < sidewaysRoom;
		var wayOutInCarTerms = leavesByTheEnd ? new Vector(signOf(local.x), 0) : new Vector(0, signOf(local.y));
		var overlap = Math.min(lengthwaysRoom, sidewaysRoom);
		return {point: point, pushFirstAway: car.inWorldTerms(wayOutInCarTerms), overlap: overlap};
	}
}
