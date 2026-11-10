package shunt.ai;

import shunt.ai.AiTuning as Ai;
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

/** One of the three kinds of AI driver: how fast, how rough, how sharp-eyed for oil. */
typedef Kind = {
	final pace:Float;
	final aggression:Float;
	final skill:Float;
}

class DriverCharacters {
	/**
	 * The three kinds of AI driver (Tom, 2 Nov: "the AIs might need to get a
	 * bit faster, one could be aggressive"). An Ace, quickest and clean; a
	 * Bruiser, nearly as quick, who would rather bump you out of the way than
	 * go round; and a Steady, the one to beat, who keeps out of trouble.
	 */
	static final kinds:Array<Kind> = [
		{pace: Ai.acePace, aggression: 0.1, skill: 0.9},
		{pace: Ai.bruiserPace, aggression: 0.95, skill: 0.5},
		{pace: Ai.steadyPace, aggression: 0.0, skill: 0.7}
	];

	/** Which kind of driver (0 Ace, 1 Bruiser, 2 Steady) an AI driver in a seat is, in a race with this seed. */
	public static function kindOf(seed:Int, seat:Int):Int {
		return (seat + seed) % kinds.length;
	}

	/**
	 * A driver for a seat in a race, from the race's seed. Seats next to each
	 * other get different kinds, so three AI cars are one of each; which seat
	 * gets which changes from race to race. Where it likes to be across the
	 * track comes from the seed too.
	 */
	public static function forSeat(seed:Int, seat:Int):DriverCharacter {
		var kind = kinds[kindOf(seed, seat)];
		var lane = SeededRandom.asFraction(SeededRandom.next(SeededRandom.startingFrom(seed * 7919 + seat * 104729 + 1)));
		return {pace: kind.pace, aggression: kind.aggression, skill: kind.skill, favouriteLane: lane * 2 - 1};
	}
}
