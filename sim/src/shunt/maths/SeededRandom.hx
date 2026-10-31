package shunt.maths;

/**
 * Random numbers that come out the same every time from the same seed, so a
 * race can be replayed exactly (SPEC.md §3). The whole generator is one
 * whole number, kept in the race's state, so a copy of a race carries on
 * with the same "random" numbers as the original.
 *
 * It is xorshift32: it shuffles the number's bits by shifting and mixing
 * them. That uses only operations JavaScript does exactly the same
 * everywhere.
 */
class SeededRandom {
	/** The generator's first state from a seed. It can't start at zero, which would give zeros for ever. */
	public static function startingFrom(seed:Int):Int {
		return seed == 0 ? 0x2545F491 : seed;
	}

	/** The next state: the old one's bits shifted and mixed. */
	public static function next(state:Int):Int {
		state ^= state << 13;
		state ^= state >>> 17;
		state ^= state << 5;
		return state;
	}

	/** A state as a fraction from 0 up to (but not including) 1. */
	public static function asFraction(state:Int):Float {
		return (state & 0x7fffffff) / 2147483648.0;
	}
}
