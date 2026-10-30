import Check.*;
import TestDrive.pedals;
import haxe.Json;
import shunt.car.Car;
import shunt.car.CarInput.CarInputs;
import shunt.race.Laps;
import shunt.race.Race;
import shunt.race.RaceEvent.EventKind;
import shunt.race.RaceState.Phase;
import shunt.race.RaceTuning;
import shunt.race.StartLights;

using shunt.car.CarFrame;

/** The race's rules (SPEC.md §6, §8). */
class RaceTests {
	public static final all:Array<Check.Test> = [
		test("the lights hold the cars, three reds a second apart, then green", lightsHoldTheCars),
		test("a lap counts after every checkpoint, crossing the line forwards", lapsCountInOrder),
		test("crossing the line with a checkpoint missed counts nothing", cuttingCountsNothing),
		test("reversing over the line and back counts nothing", reversingCountsNothing),
		test("a car turned round for 3 s is put back, facing the right way", carsArePutBack),
		test("a race ends with every finisher placed in finishing order", finishingOrder),
		test("the same seed and inputs give the same race, exactly", racesRepeat),
		test("a copied race, put back, carries on exactly as before", copiesCarryOn)
	];

	static function lightsHoldTheCars() {
		var race = TestRaces.newRace(4, 1);
		var gridSpot = race.racer(0).car.position;
		var lightTicks:Array<Int> = [];
		var movedOnRed = 0.0;
		while (race.state.phase == Lights) {
			race.step([for (_ in 0...4) pedals(1, 0, 0)]);
			for (event in race.events) if (event.kind == LightOn || event.kind == Green) lightTicks.push(race.state.tick);
			if (race.state.phase == Lights) movedOnRed = race.racer(0).car.position.distanceTo(gridSpot);
		}
		equal(movedOnRed, 0.0, "metres moved before green");
		equal(lightTicks.join(" "), [1, 2, 3, 4].map(Tick.ticksIn).join(" "), "ticks the lights changed on");
		equal(race.state.tick, StartLights.greenTick, "the tick it went green");
	}

	static function lapsCountInOrder() {
		var race = carJustBeforeTheLine(RaceTuning.checkpoints);
		TestRaces.runFor(race, 1, pedals(0.5, 0, 0));
		equal(race.racer(0).lapsStarted, 1, "laps started");
		equal(race.racer(0).nextCheckpoint, 1, "next checkpoint");
	}

	static function cuttingCountsNothing() {
		var race = carJustBeforeTheLine(RaceTuning.checkpoints - 1);
		TestRaces.runFor(race, 1, pedals(0.5, 0, 0));
		equal(race.racer(0).lapsStarted, 0, "laps started");
	}

	/** Across the line, back over it, and forwards again: only the first crossing counts. */
	static function reversingCountsNothing() {
		var race = carJustBeforeTheLine(RaceTuning.checkpoints);
		TestRaces.runFor(race, 1, pedals(0.5, 0, 0));
		TestRaces.runFor(race, 1, pedals(0, 1, 0));
		TestRaces.runFor(race, 3, pedals(0, 1, 0));
		TestRaces.runFor(race, 3, pedals(0.5, 0, 0));
		equal(race.racer(0).lapsStarted, 1, "laps started");
	}

	static function carsArePutBack() {
		var race = TestRaces.newRace(1, 1);
		race.state.phase = Racing;
		var grid = race.racer(0).car;
		race.racer(0).car = Cars.parkedAt(grid.position, grid.heading + Math.PI);
		TestRaces.runFor(race, RaceTuning.secondsInTroubleBeforeHelp + 0.1, CarInputs.nothingPressed);
		equal(race.racer(0).timesPutBack, 1, "times put back");
		between(race.racer(0).car.noseDirection().along(race.track.sample(race.racer(0).trackIndex).direction), 0.99, 1, "facing the race direction");
	}

	static function finishingOrder() {
		var race = TestRaces.aiRace(1);
		equal(race.state.phase, Finished, "the race is over");
		var finishTicks = [for (number in race.state.order) race.racer(number).finishTick].filter(tick -> tick >= 0);
		isTrue(finishTicks.length > 0, "someone finished");
		var sorted = finishTicks.copy();
		sorted.sort((a, b) -> a - b);
		equal(finishTicks.join(" "), sorted.join(" "), "finish ticks in the order shown");
	}

	static function racesRepeat() {
		equal(Json.stringify(TestRaces.aiRace(7).state), Json.stringify(TestRaces.aiRace(7).state), "the state at the end of two identical races");
	}

	/** Half a minute in: copy the race, run on 10 s, put the copy back, run the same 10 s again. */
	static function copiesCarryOn() {
		var race = TestRaces.newRace(4, 5);
		var drivers = TestRaces.aiDriversFor(race, 5);
		for (_ in 0...Tick.ticksIn(30)) race.step(TestRaces.aiInputs(race, drivers));
		var saved = race.copyState();
		for (_ in 0...Tick.ticksIn(10)) race.step(TestRaces.aiInputs(race, drivers));
		var firstTime = Json.stringify(race.state);
		race.restoreState(saved);
		for (_ in 0...Tick.ticksIn(10)) race.step(TestRaces.aiInputs(race, drivers));
		equal(Json.stringify(race.state), firstTime, "the state 10 s after the copy");
	}

	/** One car, lights green, a few metres before the line, with some checkpoints passed. */
	static function carJustBeforeTheLine(nextCheckpoint:Int):Race {
		var race = TestRaces.newRace(1, 1);
		race.state.phase = Racing;
		var index = race.track.sampleIndexBehindTheLine(3);
		var here = race.track.sample(index);
		var car = Cars.parkedAt(here.position, here.direction.angle());
		car.velocity = here.direction * 5;
		race.racer(0).car = car;
		race.racer(0).trackIndex = index;
		race.racer(0).nextCheckpoint = nextCheckpoint;
		return race;
	}
}
