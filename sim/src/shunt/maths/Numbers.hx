package shunt.maths;

/** Small sums that come up everywhere, given names that say what they do. */
class Numbers {
	/** Keeps a value between a lowest and a highest. */
	public static inline function keepBetween(value:Float, lowest:Float, highest:Float):Float {
		return value < lowest ? lowest : (value > highest ? highest : value);
	}

	/**
	 * A point part of the way from one value to another:
	 * `amount` 0 gives `from`, 1 gives `to`, 0.5 gives halfway.
	 */
	public static inline function partWay(from:Float, to:Float, amount:Float):Float {
		return from + (to - from) * amount;
	}

	/** Moves a value towards a target, but by no more than `mostChange`, never past it. */
	public static inline function stepTowards(value:Float, target:Float, mostChange:Float):Float {
		return value + keepBetween(target - value, -mostChange, mostChange);
	}

	/** 1 for a positive number, -1 for a negative one, 0 for zero. */
	public static inline function signOf(value:Float):Float {
		return value > 0 ? 1 : (value < 0 ? -1 : 0);
	}

	/** An angle given in degrees, in radians (what the maths needs). */
	public static inline function degrees(angle:Float):Float {
		return angle * Math.PI / 180;
	}

	/** The same angle, brought into the range -π to π, so headings never grow without end. */
	public static function wrapAngle(angle:Float):Float {
		var fullTurn = 2 * Math.PI;
		var turned = (angle + Math.PI) % fullTurn;
		if (turned < 0) turned += fullTurn;
		return turned - Math.PI;
	}
}
