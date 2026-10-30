package shunt.ai;

import shunt.ai.AiTuning as Ai;
import shunt.maths.Numbers.partWay;
import shunt.maths.SeededRandom;

/**
 * What makes one AI driver different from another (SPEC.md §7). Made from a
 * seed, so a race with the same seed has the same drivers.
 */
typedef DriverCharacter = {
	/** How close to the racing line's speeds it drives (a share, just under 1). */
	final pace:Float;

	/** How keen it is to bump rather than pass, 0 to 1. */
	final aggression:Float;

	/** How good it is at spotting oil, 0 to 1. */
	final skill:Float;

	/** Where across the track it likes to be: -1 well right, 0 the middle, 1 well left. */
	final favouriteLane:Float;
}

class DriverCharacters {
	/** A driver for a seat in a race, from the race's seed. */
	public static function forSeat(seed:Int, seat:Int):DriverCharacter {
		var state = SeededRandom.startingFrom(seed * 7919 + seat * 104729 + 1);
		function nextFraction() {
			state = SeededRandom.next(state);
			return SeededRandom.asFraction(state);
		}
		return {
			pace: partWay(Ai.slowestPace, Ai.fastestPace, nextFraction()),
			aggression: nextFraction(),
			skill: nextFraction(),
			favouriteLane: nextFraction() * 2 - 1
		};
	}
}
