import shunt.ai.AiDriver;
import shunt.ai.DriverCharacter;
import shunt.ai.RacingLine;
import shunt.car.CarInput;
import shunt.race.Race;
import shunt.race.RaceState.Phase;
import shunt.race.RaceTuning;
import shunt.track.Track;

/** Tracks and races for the checks, made the same way every time. */
class TestRaces {
	/** The oval, read from its file once and shared by every check. */
	public static final oval = Track.fromJson(js.Syntax.code("require('fs').readFileSync({0}, 'utf8')", "../tracks/oval.json"));

	/** The racing line for the oval, also made once. */
	public static final ovalLine = new RacingLine(oval);

	/** The longest any race is allowed to run in a check: something has gone wrong after this. */
	static inline final mostSeconds = 600;

	/** A race on the oval, lights still red. */
	public static function newRace(cars:Int, seed:Int):Race {
		return new Race(oval, {cars: cars, laps: RaceTuning.defaultLaps, seed: seed});
	}

	/** An AI driver for every seat in a race. */
	public static function aiDriversFor(race:Race, seed:Int):Array<AiDriver> {
		return [for (seat in 0...race.state.racers.length) new AiDriver(DriverCharacters.forSeat(seed, seat), ovalLine, seat)];
	}

	/** Every seat's input this tick, from its AI driver. */
	public static function aiInputs(race:Race, drivers:Array<AiDriver>):Array<CarInput> {
		return [for (seat in 0...drivers.length) drivers[seat].inputFor(race, seat)];
	}

	/** Runs a race with AI drivers until it is over (or something is badly wrong). */
	public static function runToTheEnd(race:Race, drivers:Array<AiDriver>):Race {
		while (race.state.phase != Finished && race.state.tick < Tick.ticksIn(mostSeconds)) race.step(aiInputs(race, drivers));
		return race;
	}

	/** Runs a race for a number of seconds with the same input for everyone. */
	public static function runFor(race:Race, seconds:Float, input:CarInput):Race {
		for (_ in 0...Tick.ticksIn(seconds)) race.step([for (_ in race.state.racers) input]);
		return race;
	}

	/** A four-car AI race on the oval with a seed, run to the end. */
	public static function aiRace(seed:Int):Race {
		var race = newRace(4, seed);
		return runToTheEnd(race, aiDriversFor(race, seed));
	}
}
