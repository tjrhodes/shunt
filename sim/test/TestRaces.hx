import haxe.Json;
import shunt.ai.AiDriver;
import shunt.ai.DriverCharacter;
import shunt.ai.RacingLine;
import shunt.car.CarInput;
import shunt.race.Race;
import shunt.race.RaceState.Phase;
import shunt.track.Track;

/** Tracks and races for the checks, made the same way every time. */
class TestRaces {
	/** The text of every track's file, from the same list the game reads (`tracks/index.json`). */
	public static final everyTrackText:Array<String> = [for (file in (Json.parse(fileText("index.json")) : Array<String>)) fileText(file)];

	/** Every track, read once. */
	public static final everyTrack:Array<Track> = everyTrackText.map(Track.fromJson);

	/** The oval, which most checks use: the first track in the list. */
	public static final oval = everyTrack[0];

	/** Each track's racing line, made once, in the same order as `everyTrack`. */
	static final racingLines = everyTrack.map(track -> new RacingLine(track));

	/** The oval's racing line. */
	public static final ovalLine = racingLines[0];

	static function fileText(name:String):String {
		return js.Syntax.code("require('fs').readFileSync({0}, 'utf8')", '../tracks/$name');
	}

	/** The longest any race is allowed to run in a check: something has gone wrong after this. */
	static inline final mostSeconds = 600;

	/** A race on a track (the oval, unless another is given), lights still red, its usual number of laps. */
	public static function newRace(cars:Int, seed:Int, ?track:Track):Race {
		var where = track ?? oval;
		return new Race(where, {cars: cars, laps: where.laps, seed: seed});
	}

	/** An AI driver for every seat in a race, following its track's racing line. */
	public static function aiDriversFor(race:Race, seed:Int):Array<AiDriver> {
		var line = racingLines[everyTrack.indexOf(race.track)];
		return [for (seat in 0...race.state.racers.length) new AiDriver(DriverCharacters.forSeat(seed, seat), line, seat)];
	}

	/** Every seat's input this tick, from its AI driver. */
	public static function aiInputs(race:Race, drivers:Array<AiDriver>):Array<CarInput> {
		return [for (seat in 0...drivers.length) drivers[seat].inputFor(race, seat)];
	}

	/** Runs a race with AI drivers until it is over (or something is badly wrong), showing each tick to `watch` if given. */
	public static function runToTheEnd(race:Race, drivers:Array<AiDriver>, ?watch:Race -> Void):Race {
		while (race.state.phase != Finished && race.state.tick < Tick.ticksIn(mostSeconds)) {
			race.step(aiInputs(race, drivers));
			if (watch != null) watch(race);
		}
		return race;
	}

	/** Runs a race for a number of seconds with the same input for everyone. */
	public static function runFor(race:Race, seconds:Float, input:CarInput):Race {
		for (_ in 0...Tick.ticksIn(seconds)) race.step([for (_ in race.state.racers) input]);
		return race;
	}

	/** A four-car AI race with a seed, on a track (the oval, unless another is given), run to the end. */
	public static function aiRace(seed:Int, ?track:Track, ?watch:Race -> Void):Race {
		var race = newRace(4, seed, track);
		return runToTheEnd(race, aiDriversFor(race, seed), watch);
	}
}
