package shunt.race;

import shunt.car.Car;
import shunt.car.CarTuning;
import shunt.car.Damage;
import shunt.contact.CarContacts;
import shunt.contact.ContactTuning as Tuning;
import shunt.contact.Impacts;
import shunt.contact.WallContacts;
import shunt.maths.Vector;

/**
 * Sorting out every hit in a tick: cars against walls, then every pair of
 * cars against each other. Hard hits batter the cars (SPEC.md §4b).
 */
class Bumping {
	/** A change of speed (m/s) smaller than this makes no sparks or sound, so a car resting on a wall stays quiet. */
	static inline final noticeableSpeedChange = 0.5;

	public static function sortOutEveryHit(race:Race) {
		var count = race.state.racers.length;
		for (number in 0...count) hitWalls(race, number);
		for (first in 0...count) {
			for (second in first + 1...count) hitEachOther(race, first, second);
		}
	}

	/** Every wall a car is touching shoves it back off. */
	static function hitWalls(race:Race, number:Int) {
		var car = race.racer(number).car;
		for (contact in WallContacts.of(car, race.track)) {
			var shove = Impacts.shoveApart(car, null, contact, Tuning.wallBounce, Tuning.wallScrape);
			var speedChange = takeTheHit(car, shove, contact.point);
			if (speedChange > noticeableSpeedChange) race.tell(WallHit, number, -1, contact.point, speedChange);
		}
	}

	/** Two cars touching shove each other apart, equally and oppositely. A car just put back passes through. */
	static function hitEachOther(race:Race, first:Int, second:Int) {
		var firstCar = race.racer(first).car;
		var secondCar = race.racer(second).car;
		if (race.racer(first).ghostTicks > 0 || race.racer(second).ghostTicks > 0) return;
		var contact = CarContacts.deepestBetween(firstCar, secondCar);
		if (contact == null) return;
		var shove = Impacts.shoveApart(firstCar, secondCar, contact, Tuning.carBounce, Tuning.carScrape);
		takeTheHit(secondCar, shove, contact.point);
		var speedChange = takeTheHit(firstCar, shove, contact.point);
		if (speedChange > noticeableSpeedChange) race.tell(CarHit, first, second, contact.point, speedChange);
	}

	/** A shove changes a car's speed; a big enough change batters the side that was hit. Returns the change. */
	static function takeTheHit(car:Car, shove:Float, point:Vector):Float {
		var speedChange = shove / CarTuning.mass;
		car.damage = Damage.afterHit(car, speedChange, point);
		return speedChange;
	}
}
