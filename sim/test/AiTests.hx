import Check.*;
import shunt.car.Damage;
import shunt.race.Laps;
import shunt.track.Track;

/** The AI drivers, raced against each other (SPEC.md §7, §8). */
class AiTests {
	static inline final races = 100;

	/** Put back on the track more than this many times in one race, and something is wrong with the driving. */
	static inline final mostTimesPutBack = 3;

	/**
	 * Bumping is the point, so now and then two cars tangle, spin, and one
	 * drops right back: a racing incident. One car in a hundred may.
	 */
	static inline final racingIncidentsAllowed = races * 4 / 100;

	public static final all:Array<Check.Test> = [
		for (track in TestRaces.everyTrack)
			test('${track.name}: four AI cars, $races seeded races: all but wrecks and the odd incident reach the last lap, none put back over $mostTimesPutBack times, none out of an arena', () -> aiCarsRace(track))
	];

	/**
	 * A car that isn't badly damaged should keep up well enough to reach the
	 * last lap (the 10 s after the leader can stop it finishing). A badly
	 * damaged one may fall right back: that is damage working, not bad
	 * driving. So may the odd car caught in a racing incident. And on an
	 * arena, no car may ever be outside its outline.
	 */
	static function aiCarsRace(track:Track) {
		var ticksOutside = 0;
		var finishedRaces = [for (seed in 1...races + 1) TestRaces.aiRace(seed, track, race -> ticksOutside += carsOutsideTheArena(race))];
		var everyRacer = Lambda.flatten(finishedRaces.map(race -> race.state.racers.map(racer -> {racer: racer, laps: race.state.laps})));
		var stragglers = everyRacer.filter(entry -> !keptUp(entry.racer, entry.laps) && !Damage.isLeakingOil(entry.racer.car)).length;
		var mostPutBack = Lambda.fold(everyRacer, (entry, most) -> Std.int(Math.max(most, entry.racer.timesPutBack)), 0);
		between(stragglers, 0, racingIncidentsAllowed, "cars not badly damaged that didn't reach the last lap");
		between(mostPutBack, 0, mostTimesPutBack, "most times one car was put back in a race");
		equal(ticksOutside, 0, "ticks a car spent outside the arena");
	}

	/** Finished, or at least on the last lap. */
	static function keptUp(racer:shunt.race.RaceState.Racer, laps:Int):Bool {
		return racer.finishTick >= 0 || Laps.lapsDone(racer) >= laps - 1;
	}

	/** How many cars are outside an arena's outline (its box: the arenas so far are boxes). None on a road. */
	static function carsOutsideTheArena(race:shunt.race.Race):Int {
		var outline = race.track.arenaOutline;
		if (outline.length == 0) return 0;
		var xs = outline.map(spot -> spot.x);
		var ys = outline.map(spot -> spot.y);
		function isOutside(spot:shunt.maths.Vector) return spot.x < Lambda.fold(xs, Math.min, 1e9) || spot.x > Lambda.fold(xs, Math.max, -1e9) || spot.y < Lambda.fold(ys, Math.min, 1e9) || spot.y > Lambda.fold(ys, Math.max, -1e9);
		return race.state.racers.filter(racer -> isOutside(racer.car.position)).length;
	}
}
