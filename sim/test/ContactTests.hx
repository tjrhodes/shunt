import Check.*;
import shunt.car.Car;
import shunt.car.CarInput;
import shunt.car.CarTuning;
import shunt.contact.CarContacts;
import shunt.contact.CarShape;
import shunt.contact.ContactTuning;
import shunt.contact.Impacts;
import shunt.maths.SeededRandom;
import shunt.maths.Vector;
import shunt.race.Race;

using shunt.car.CarFrame;

/** Hits: cars against cars, cars against walls (SPEC.md §4, §8). */
class ContactTests {
	/** How many random runs at the walls. */
	static inline final wallRuns = 10000;

	public static final all:Array<Check.Test> = [
		test("a head-on hit keeps all the momentum", headOnKeepsMomentum),
		test("a side hit keeps all the momentum", sideHitKeepsMomentum),
		test("cars pushing into each other don't stay overlapped", noOverlapRemains),
		test("a tap on a back corner turns the car", tapTurnsTheCar),
		test('$wallRuns random runs at the walls: no car gets out', wallsHold),
		test("a car flat out into a wall at 5° to 20° slides along it, never spearing in", wallsAreGlancedOff)
	];

	static function headOnKeepsMomentum() {
		var first = carAt(0, 0, 0, new Vector(10, 0));
		var second = carAt(CarTuning.length - 0.2, 0.3, Math.PI, new Vector(-10, 0));
		momentumIsKeptWhenThey(first, second);
	}

	static function sideHitKeepsMomentum() {
		var first = carAt(0, 0, 0, new Vector(3, 0));
		var second = carAt(1, CarTuning.width / 2 + CarTuning.length / 2 - 0.2, -Math.PI / 2, new Vector(0, -8));
		momentumIsKeptWhenThey(first, second);
	}

	/** Hits two touching cars together, and compares their momentum before and after. */
	static function momentumIsKeptWhenThey(first:Car, second:Car) {
		var before = (first.velocity + second.velocity) * CarTuning.mass;
		var size = (first.velocity.length() + second.velocity.length()) * CarTuning.mass;
		var contact = CarContacts.deepestBetween(first, second);
		isTrue(contact != null, "the cars touch");
		var shove = Impacts.shoveApart(first, second, contact, ContactTuning.carBounce, ContactTuning.carScrape);
		var after = (first.velocity + second.velocity) * CarTuning.mass;
		isTrue(shove > 0, "they were shoved apart");
		between(after.distanceTo(before), 0, 0.01 * size, "momentum lost or gained");
	}

	/** Two cars nose to nose on the oval's straight, both flat out for two seconds. */
	static function noOverlapRemains() {
		var race = racingOnTheOval(2);
		var start = race.track.sample(0);
		race.racer(0).car = carAt(start.position.x - 3, start.position.y, 0, Vector.nothing());
		race.racer(1).car = carAt(start.position.x + 3, start.position.y, Math.PI, Vector.nothing());
		TestRaces.runFor(race, 2, TestDrive.pedals(1, 0, 0));
		var overlap = CarContacts.deepestBetween(race.racer(0).car, race.racer(1).car);
		between(overlap == null ? 0 : overlap.overlap, 0, 0.1, "metres of overlap after pushing for 2 s");
	}

	/** A car driving into the back right corner of a still one, at an angle. */
	static function tapTurnsTheCar() {
		var still = carAt(0, 0, 0, Vector.nothing());
		var hitter = carAt(-CarTuning.length + 0.1, -1.2, 0.3, new Vector(6, 0));
		var contact = CarContacts.deepestBetween(hitter, still);
		isTrue(contact != null, "the cars touch");
		Impacts.shoveApart(hitter, still, contact, ContactTuning.carBounce, ContactTuning.carScrape);
		isTrue(Math.abs(still.spin) > 0.3, 'the car hit spins (${still.spin} rad/s)');
	}

	/**
	 * A car put anywhere on the oval, pointing anywhere, at any speed, then
	 * driven any old how for a moment: its middle must always stay between
	 * the walls.
	 */
	static function wallsHold() {
		var random = SeededRandom.startingFrom(99);
		var escapes = 0;
		var race = racingOnTheOval(1);
		for (_ in 0...wallRuns) {
			var numbers = [for (_ in 0...6) SeededRandom.asFraction(random = SeededRandom.next(random))];
			placeCarAnyOldWhere(race, numbers);
			for (_ in 0...Tick.ticksIn(0.75)) {
				race.step([TestDrive.pedals(numbers[3], 0, numbers[4] * 2 - 1)]);
				if (isOutside(race)) escapes++;
			}
		}
		equal(escapes, 0, "ticks with a car's middle outside the walls");
	}

	/**
	 * Tom's third drive: the front corner caught in the wall and the car
	 * speared in, stopped and turned. At every angle it must keep at least
	 * half its speed and end up pointing along the track, not into the wall.
	 */
	static function wallsAreGlancedOff() {
		for (degreesIn in [5, 10, 15, 20]) {
			var race = racingOnTheOval(1);
			var start = race.track.sample(30);
			var nearTheRightWall = start.position + race.track.leftAt(30) * (3.5 - start.width / 2);
			var heading = start.direction.angle() - degreesIn * Math.PI / 180;
			race.racer(0).car = carAt(nearTheRightWall.x, nearTheRightWall.y, heading, Vector.pointingAt(heading) * 40);
			race.racer(0).trackIndex = 30;
			TestRaces.runFor(race, 1.5, TestDrive.pedals(1, 0, 0));
			var car = race.racer(0).car;
			between(car.speed(), 20, 50, 'm/s after hitting the wall at $degreesIn°');
			isTrue(car.noseDirection().along(race.track.leftAt(race.racer(0).trackIndex)) > -0.2, 'not pointing into the wall after $degreesIn°');
		}
	}

	static function placeCarAnyOldWhere(race:Race, numbers:Array<Float>) {
		var track = race.track;
		var index = Math.floor(numbers[0] * track.samples.length);
		var roomToTurnRound = track.sample(index).width / 2 - CarShape.reach - ContactTuning.wallHalfThickness;
		var spot = track.sample(index).position + track.leftAt(index) * ((numbers[1] * 2 - 1) * roomToTurnRound);
		var heading = numbers[2] * 2 * Math.PI;
		race.racer(0).car = carAt(spot.x, spot.y, heading, Vector.pointingAt(heading) * (numbers[5] * CarTuning.topSpeed));
		race.racer(0).trackIndex = index;
	}

	static function isOutside(race:Race):Bool {
		var racer = race.racer(0);
		return Math.abs(race.track.howFarLeft(racer.car.position, racer.trackIndex)) > race.track.sample(racer.trackIndex).width / 2;
	}

	/** A race on the oval with the lights already green. */
	static function racingOnTheOval(cars:Int):Race {
		var race = TestRaces.newRace(cars, 1);
		race.state.phase = Racing;
		return race;
	}

	public static function carAt(x:Float, y:Float, heading:Float, velocity:Vector):Car {
		var car = Cars.parkedAt(new Vector(x, y), heading);
		car.velocity = velocity;
		return car;
	}
}
