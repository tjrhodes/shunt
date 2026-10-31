package shunt.contact;

import shunt.car.Car;

/**
 * Where two cars touch: a corner of one inside the other. Cars move less
 * than a quarter of their width per tick, so a corner always gets inside
 * before the boxes could pass through each other.
 */
class CarContacts {
	/** The deepest place where `first` and `second` overlap, with the way to push `first` off `second`; null if apart. */
	public static function deepestBetween(first:Car, second:Car):Null<Contact> {
		if (first.position.distanceTo(second.position) > 2 * CarShape.reach) return null;
		var deepest:Null<Contact> = null;
		for (corner in CarShape.corners(first)) deepest = deeperOf(deepest, CarShape.pointInside(second, corner, 0));
		for (corner in CarShape.corners(second)) deepest = deeperOf(deepest, turnedRound(CarShape.pointInside(first, corner, 0)));
		return deepest;
	}

	/**
	 * A corner of `second` inside `first` leaves `first` one way, which is
	 * the way to push `second`; so `first` is pushed the opposite way.
	 */
	static function turnedRound(contact:Null<Contact>):Null<Contact> {
		if (contact == null) return null;
		return {point: contact.point, pushFirstAway: contact.pushFirstAway * -1, overlap: contact.overlap};
	}

	static function deeperOf(current:Null<Contact>, candidate:Null<Contact>):Null<Contact> {
		if (candidate == null) return current;
		return current == null || candidate.overlap > current.overlap ? candidate : current;
	}
}
