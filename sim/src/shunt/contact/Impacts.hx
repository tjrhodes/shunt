package shunt.contact;

import shunt.car.Car;
import shunt.car.CarTuning as Tuning;
import shunt.maths.Numbers.keepBetween;
import shunt.maths.Vector;

/**
 * What happens when two things touch: a short, sharp shove (an impulse) at
 * the point of contact that stops them going into each other, plus a
 * sideways rub that slows any scraping. Because the shove lands at a point,
 * not through the middle, it can spin a car too: a tap on a rear corner
 * turns the car, all by itself.
 *
 * Equal and opposite shoves go to both cars, so between them they keep
 * all their momentum. A wall is a car that can't be moved (`second` null).
 */
class Impacts {
	/**
	 * Shoves `first` (and `second`, if it is a car) apart at a contact, and
	 * pushes them out of each other. Returns how hard the shove was, in
	 * newton-seconds, so damage and sound can follow from it.
	 */
	public static function shoveApart(first:Car, second:Null<Car>, contact:Contact, bounce:Float, scrape:Float):Float {
		var shove = shoveThemApart(first, second, contact, bounce);
		rubAlongTheContact(first, second, contact, scrape * shove);
		moveOutOfEachOther(first, second, contact);
		return shove;
	}

	/**
	 * The shove straight across the contact: enough to stop them closing in,
	 * and (with some bounce) to send them apart. It only ever pushes apart.
	 */
	static function shoveThemApart(first:Car, second:Null<Car>, contact:Contact, bounce:Float):Float {
		var across = contact.pushFirstAway;
		var closing = closingSpeedAlong(first, second, contact, across);
		if (closing >= 0) return 0;
		var shove = -(1 + bounce) * closing / stiffnessAlong(first, second, contact, across);
		applyShove(first, second, contact, across * shove);
		return shove;
	}

	/**
	 * The rub along the contact, against any scraping, as friction does: it
	 * tries to stop the scrape, but can be no stronger than `mostRub`, which
	 * grows with how hard they were shoved together.
	 */
	static function rubAlongTheContact(first:Car, second:Null<Car>, contact:Contact, mostRub:Float) {
		var along = contact.pushFirstAway.turnedLeft();
		var scraping = closingSpeedAlong(first, second, contact, along);
		var rub = keepBetween(-scraping / stiffnessAlong(first, second, contact, along), -mostRub, mostRub);
		applyShove(first, second, contact, along * rub);
	}

	/** How fast the contact points move apart along a direction (negative when closing in). */
	static function closingSpeedAlong(first:Car, second:Null<Car>, contact:Contact, direction:Vector):Float {
		var firstMoving = pointVelocity(first, contact.point);
		var secondMoving = second == null ? Vector.nothing() : pointVelocity(second, contact.point);
		return (firstMoving - secondMoving).along(direction);
	}

	/** How fast a point on a car moves: the car's speed plus the swing from its spin. */
	static function pointVelocity(car:Car, point:Vector):Vector {
		return car.velocity + (point - car.position).turnedLeft() * car.spin;
	}

	/**
	 * How much the contact points' speed apart changes for each unit of
	 * shove: light things and things easily spun give way more.
	 */
	static function stiffnessAlong(first:Car, second:Null<Car>, contact:Contact, direction:Vector):Float {
		var giving = howMuchCarGives(first, contact.point, direction);
		return second == null ? giving : giving + howMuchCarGives(second, contact.point, direction);
	}

	static function howMuchCarGives(car:Car, point:Vector, direction:Vector):Float {
		var lever = (point - car.position).turning(direction);
		return 1 / Tuning.mass + lever * lever / Tuning.turningInertia;
	}

	/** Gives `first` a shove at the contact point, and `second` the same shove the other way. */
	static function applyShove(first:Car, second:Null<Car>, contact:Contact, shove:Vector) {
		shoveCar(first, contact.point, shove);
		if (second != null) shoveCar(second, contact.point, shove * -1);
	}

	/** A shove at a point changes how fast the car moves, and how fast it spins (by how far off-centre it lands). */
	static function shoveCar(car:Car, point:Vector, shove:Vector) {
		car.velocity = car.velocity + shove * (1 / Tuning.mass);
		car.spin += (point - car.position).turning(shove) / Tuning.turningInertia;
	}

	/** Moves overlapping things most of the way out of each other; two cars share the move, a wall doesn't budge. */
	static function moveOutOfEachOther(first:Car, second:Null<Car>, contact:Contact) {
		var move = contact.pushFirstAway * (contact.overlap * ContactTuning.pushApartShare);
		if (second == null) {
			first.position = first.position + move;
			return;
		}
		first.position = first.position + move * 0.5;
		second.position = second.position - move * 0.5;
	}
}
