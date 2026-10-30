import Check.*;
import shunt.car.Damage;
import shunt.race.Laps;

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
		test('four AI cars, $races seeded races: all but wrecks and the odd incident reach the last lap, none put back over $mostTimesPutBack times', aiCarsRace)
	];

	/**
	 * A car that isn't badly damaged should keep up well enough to reach the
	 * last lap (the 10 s after the leader can stop it finishing). A badly
	 * damaged one may fall right back: that is damage working, not bad
	 * driving. So may the odd car caught in a racing incident.
	 */
	static function aiCarsRace() {
		var stragglers = 0;
		var mostPutBack = 0;
		for (seed in 1...races + 1) {
			var race = TestRaces.aiRace(seed);
			for (racer in race.state.racers) {
				var keptUp = racer.finishTick >= 0 || Laps.lapsDone(racer) >= race.state.laps - 1;
				if (!keptUp && !Damage.isLeakingOil(racer.car)) stragglers++;
				mostPutBack = Std.int(Math.max(mostPutBack, racer.timesPutBack));
			}
		}
		between(stragglers, 0, racingIncidentsAllowed, "cars not badly damaged that didn't reach the last lap");
		between(mostPutBack, 0, mostTimesPutBack, "most times one car was put back in a race");
	}
}
