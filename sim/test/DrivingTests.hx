import Check.*;
import TestDrive.pedals;
import haxe.Json;
import shunt.car.Car;
import shunt.car.CarInput;
import shunt.car.CarTuning as Tuning;
import shunt.maths.Numbers.keepBetween;

using shunt.car.CarFrame;

/**
 * One car on an empty car park: does it drive like a car? (SPEC.md §8.)
 * The ranges here are the spec's targets; the car's own numbers are always
 * read from `CarTuning`, never copied.
 */
class DrivingTests {
	static final floored = pedals(1, 0, 0);
	static final fullBrakes = pedals(0, 1, 0);
	static final kilometresPerHour = 1 / 3.6;

	/** Every check, in the order they run. */
	public static final all:Array<Check.Test> = [
		test("pulls away from 0 to 100 km/h in 3.5 to 4.5 s", pullsAway),
		test("tops out just under its top speed", topsOut),
		test("hands off, it runs dead straight", runsStraight),
		test("brakes stop it without ever rolling it backwards", brakesStop),
		test("holding the brake when stopped reverses, slowly", reverses),
		test("steering right turns right, and left turns left", steersTheRightWay),
		test("a gentle bend at speed holds without sliding", holdsAGentleBend),
		test("at a crawl on full lock it turns in a tight circle", turnsTightlyWhenSlow),
		test("flat out on full lock it slides, but nothing breaks", survivesAbuse),
		test("the same inputs always give the same drive", isRepeatable),
		test("a copied car carries on exactly as the original", copiesCarryOn),
		test("inputs out of range count as the most allowed", tidiesInputs)
	];

	static function pullsAway() {
		var drive = new TestDrive().holdUntil(floored, car -> car.speed() >= 100 * kilometresPerHour, 10);
		between(drive.time, 3.5, 4.5, "seconds to 100 km/h");
	}

	static function topsOut() {
		var car = new TestDrive().hold(floored, 40).car;
		between(car.speed(), 0.9 * Tuning.topSpeed, Tuning.topSpeed, "speed after 40 s flat out");
	}

	static function runsStraight() {
		var car = new TestDrive().hold(floored, 10).car;
		equal(car.heading, 0.0, "heading");
		equal(car.sidewaysSpeed(), 0.0, "sideways speed");
	}

	/** From flat out to a stop: a short distance, and never backwards on the way. */
	static function brakesStop() {
		var drive = new TestDrive().hold(floored, 40);
		var startX = drive.car.position.x;
		var slowestForwards = Math.POSITIVE_INFINITY;
		drive.holdUntil(fullBrakes, car -> {
			slowestForwards = Math.min(slowestForwards, car.forwardSpeed());
			return car.forwardSpeed() < Tuning.stoppedBelow;
		}, 20);
		between(drive.car.position.x - startX, 50, 110, "metres to stop from flat out");
		isTrue(slowestForwards >= 0, 'never rolls backwards while braking (slowest ${slowestForwards})');
	}

	static function reverses() {
		var car = new TestDrive().hold(fullBrakes, 10).car;
		between(-car.forwardSpeed(), 0.8 * Tuning.reverseTopSpeed, Tuning.reverseTopSpeed, "reverse speed after 10 s");
	}

	/** Heading is anticlockwise, so turning right makes it go down. */
	static function steersTheRightWay() {
		var right = new TestDrive().hold(pedals(0.5, 0, 0), 2).hold(pedals(0.5, 0, 1), 1).car;
		var left = new TestDrive().hold(pedals(0.5, 0, 0), 2).hold(pedals(0.5, 0, -1), 1).car;
		isTrue(right.heading < -0.3, 'right turns clockwise (heading ${right.heading})');
		isTrue(left.heading > 0.3, 'left turns anticlockwise (heading ${left.heading})');
	}

	/**
	 * At about 90 km/h, a light touch of steering (a tenth of the way, which
	 * asks for about half of what the tyres can hold): the car turns and its
	 * tyres keep hold.
	 */
	static function holdsAGentleBend() {
		var drive = new TestDrive().holdUntil(floored, car -> car.speed() >= 25, 10);
		var car = drive.follow(_ -> pedals(holdSpeed(drive.car, 25), 0, 0.1), 5).car;
		between(Math.abs(car.sidewaysSpeed()), 0, 1.5, "sideways slide on a gentle bend");
		between(Math.abs(car.spin), 0.1, 1.0, "steady turning rate");
	}

	/** At walking pace on full lock: a circle a few car lengths across, about what the wheelbase allows. */
	static function turnsTightlyWhenSlow() {
		var drive = new TestDrive();
		var furthest = 0.0;
		drive.follow(_ -> {
			furthest = Math.max(furthest, drive.car.position.length());
			return pedals(holdSpeed(drive.car, 1.5), 0, -1);
		}, 30);
		var circleAcross = 2 * Tuning.wheelbase / Math.tan(Tuning.mostSteeringWhenSlow);
		between(furthest, 0.8 * circleAcross, 1.3 * circleAcross, "widest point of the slow circle");
	}

	static function survivesAbuse() {
		var drive = new TestDrive().hold(floored, 15).hold(pedals(1, 0, 1), 3).hold(pedals(1, 1, -1), 3);
		isTrue(isFinite(drive.car), "every number is still a real number");
		isTrue(Math.abs(drive.car.sidewaysSpeed()) > 1, "it slid");
	}

	static function isRepeatable() {
		var first = Json.stringify(new TestDrive().follow(wigglyInput, 20).car);
		var second = Json.stringify(new TestDrive().follow(wigglyInput, 20).car);
		equal(second, first, "the car after two identical drives");
	}

	static function copiesCarryOn() {
		var original = new TestDrive().follow(wigglyInput, 5);
		var copy = new TestDrive(Cars.copyOf(original.car));
		original.hold(pedals(1, 0, 0.5), 3);
		copy.hold(pedals(1, 0, 0.5), 3);
		equal(Json.stringify(copy.car), Json.stringify(original.car), "the copy after 3 more seconds");
	}

	static function tidiesInputs() {
		var wild = Json.stringify(new TestDrive().hold(pedals(7, -2, 5), 5).car);
		var tidy = Json.stringify(new TestDrive().hold(pedals(1, 0, 1), 5).car);
		equal(wild, tidy, "the car driven with wild inputs");
	}

	/** A driver who is all over the place, the same way every time. */
	static function wigglyInput(seconds:Float):CarInput {
		return pedals(Math.abs(Math.sin(seconds)), seconds % 7 > 6 ? 1 : 0, Math.sin(seconds * 2.3));
	}

	/** A simple cruise control: more throttle below the speed wanted, none above. */
	static function holdSpeed(car:Car, wanted:Float):Float {
		return keepBetween((wanted - car.speed()) * 0.5 + 0.3, 0, 1);
	}

	static function isFinite(car:Car):Bool {
		var numbers = [car.position.x, car.position.y, car.velocity.x, car.velocity.y, car.heading, car.spin];
		return Lambda.foreach(numbers, Math.isFinite);
	}
}
