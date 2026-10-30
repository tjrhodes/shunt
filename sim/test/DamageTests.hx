import Check.*;
import TestDrive.pedals;
import shunt.car.Car;
import shunt.car.CarInput.CarInputs;
import shunt.car.Damage.DamageZones;
import shunt.car.CarTuning;
import shunt.car.Damage;
import shunt.car.DamageTuning as Harm;
import shunt.maths.Vector;
import shunt.race.OilSpill;
import shunt.race.RaceEvent.EventKind;

using shunt.car.CarFrame;

/** Damage and oil (SPEC.md §4b, §8). Expected numbers come from `DamageTuning`, never copied. */
class DamageTests {
	static final wrecked:DamageZones = {front: 100, rear: 100, left: 100, right: 100};
	static final leftSide = new Vector(0, CarTuning.width / 2);

	public static final all:Array<Check.Test> = [
		test("a nudge under the harmless limit does no damage", nudgesAreFree),
		test("a hard hit batters only the side that was hit", hitsBatterOneSide),
		test("a wrecked car tops out at three quarters of its top speed", wrecksAreSlower),
		test("a bent front pulls towards its more damaged side", bentFrontsPull),
		test("a wrecked car can still be driven", wrecksStillDrive),
		test("no oil from a car that isn't badly damaged", noOilWhenNotBadlyDamaged),
		test("a badly damaged car drops oil now and then, not all the time", oilNowAndThen),
		test("a car crossing oil in a bend spins", oilSpinsCars)
	];

	static function nudgesAreFree() {
		var car = Cars.parkedAt(Vector.nothing(), 0);
		equal(Damage.afterHit(car, Harm.harmlessBelow - 0.5, leftSide), car.damage, "damage after a nudge");
	}

	static function hitsBatterOneSide() {
		var car = Cars.parkedAt(Vector.nothing(), 0);
		var after = Damage.afterHit(car, 10, leftSide);
		between(after.left, (10 - Harm.harmlessBelow) * Harm.pointsPerSpeedChange - 0.01, (10 - Harm.harmlessBelow) * Harm.pointsPerSpeedChange + 0.01, "left side after a 10 m/s hit");
		equal(after.front + after.rear + after.right, 0.0, "damage anywhere else");
	}

	static function wrecksAreSlower() {
		var topSpeedWhenWrecked = CarTuning.topSpeed * (1 - Harm.mostSpeedLost);
		var car = withDamage(wrecked).hold(pedals(1, 0, 0), 40).car;
		between(car.speed(), 0.9 * topSpeedWhenWrecked, topSpeedWhenWrecked, "top speed when wrecked");
	}

	/** A smashed front with the right side worse: hands off, the car turns right (clockwise). */
	static function bentFrontsPull() {
		var car = withDamage({front: 100, rear: 0, left: 0, right: 50}).hold(pedals(0.6, 0, 0), 4).car;
		isTrue(car.heading < -0.3, 'turned right with hands off (heading ${car.heading})');
	}

	static function wrecksStillDrive() {
		var car = withDamage(wrecked).hold(pedals(1, 0, 0), 3).hold(pedals(0.5, 0, 1), 2).car;
		isTrue(car.speed() > 5, "it gets going");
		isTrue(car.heading < -0.5, "it still turns");
	}

	static function noOilWhenNotBadlyDamaged() {
		var race = parkedCarWithDamage(Harm.leaksOilFrom - 1);
		TestRaces.runFor(race, 30, CarInputs.nothingPressed);
		equal(race.state.oil.length, 0, "oil patches");
	}

	/** Badly damaged, parked for a minute: every gap between drops is between the shortest and longest. */
	static function oilNowAndThen() {
		var race = parkedCarWithDamage(90);
		var drops:Array<Int> = [];
		for (_ in 0...Tick.ticksIn(60)) {
			race.step([CarInputs.nothingPressed]);
			for (event in race.events) if (event.kind == OilDropped) drops.push(race.state.tick);
		}
		isTrue(drops.length >= 6, '${drops.length} drops in a minute');
		for (index in 1...drops.length) between((drops[index] - drops[index - 1]) / Tick.perSecond, Harm.shortestOilGap, Harm.longestOilGap, "seconds between drops");
	}

	/** Two cars in the same bend at the same speed; one runs over oil. It ends up facing far off where the other does. */
	static function oilSpinsCars() {
		var clean = new TestDrive().holdUntil(pedals(1, 0, 0), car -> car.speed() > 22, 10).hold(pedals(0.3, 0, 0.25), 0.4);
		var oily = new TestDrive().holdUntil(pedals(1, 0, 0), car -> car.speed() > 22, 10);
		oily.ground = OilSpill.groundWithOil([{position: oily.car.position + Vector.pointingAt(0) * 4, ticksLeft: Tick.ticksIn(Harm.oilLasts)}]);
		oily.hold(pedals(0.3, 0, 0.25), 0.4);
		clean.hold(pedals(0.3, 0, 0.25), 1.5);
		oily.hold(pedals(0.3, 0, 0.25), 1.5);
		isTrue(Math.abs(oily.car.heading - clean.car.heading) > Math.PI / 2, 'the oily car turned ${oily.car.heading - clean.car.heading} rad more');
	}

	static function withDamage(zones:DamageZones):TestDrive {
		var drive = new TestDrive();
		drive.car.damage = zones;
		return drive;
	}

	/** A one-car race, lights green, the car parked with the same damage all round. */
	static function parkedCarWithDamage(everyZone:Float):shunt.race.Race {
		var race = TestRaces.newRace(1, 3);
		race.state.phase = Racing;
		race.racer(0).car.damage = {front: everyZone, rear: everyZone, left: everyZone, right: everyZone};
		return race;
	}
}
