package shunt.maths;

/** The two numbers inside an arrow: how far east (x) and how far north (y). */
typedef VectorData = {
	final x:Float;
	final y:Float;
}

/**
 * An arrow on the flat ground, in metres (for places) or metres per second
 * (for speeds), or newtons (for pushes).
 *
 * An arrow is never changed once it is made: adding two arrows makes a new
 * one. That means a copy of a car can safely share its arrows with the
 * original, so copying a whole race is cheap and can't go wrong.
 *
 * Underneath it is a plain `{x, y}` object, so it turns into JSON as it is.
 */
@:forward(x, y)
abstract Vector(VectorData) from VectorData to VectorData {
	public inline function new(x:Float, y:Float) {
		this = {x: x, y: y};
	}

	/** An arrow of no length: standing still, or no push at all. */
	public static inline function nothing():Vector {
		return new Vector(0, 0);
	}

	/** An arrow one long, pointing at an angle measured anticlockwise from east. */
	public static inline function pointingAt(angle:Float):Vector {
		return new Vector(Math.cos(angle), Math.sin(angle));
	}

	@:op(A + B) public inline function plus(other:Vector):Vector {
		return new Vector(this.x + other.x, this.y + other.y);
	}

	@:op(A - B) public inline function minus(other:Vector):Vector {
		return new Vector(this.x - other.x, this.y - other.y);
	}

	/** The same arrow, made longer or shorter (or turned round, if `amount` is negative). */
	@:op(A * B) public inline function times(amount:Float):Vector {
		return new Vector(this.x * amount, this.y * amount);
	}

	/** How far this arrow reaches along a direction (a dot product). */
	public inline function along(direction:Vector):Float {
		return this.x * direction.x + this.y * direction.y;
	}

	/** The arrow's length. */
	public inline function length():Float {
		return Math.sqrt(this.x * this.x + this.y * this.y);
	}

	/** The same arrow, given a quarter turn to the left (anticlockwise). */
	public inline function turnedLeft():Vector {
		return new Vector(-this.y, this.x);
	}

	/**
	 * How much this arrow turns the other one anticlockwise (a 2D cross
	 * product): for an arrow from a car's middle to where it is pushed, how
	 * much the push will spin the car.
	 */
	public inline function turning(other:Vector):Float {
		return this.x * other.y - this.y * other.x;
	}

	/** The same direction, one long (or no arrow at all, if it had no length). */
	public function lengthOne():Vector {
		var howLong = length();
		return howLong > 0 ? times(1 / howLong) : nothing();
	}

	/** The angle this arrow points at, anticlockwise from east. */
	public inline function angle():Float {
		return Math.atan2(this.y, this.x);
	}

	/** How far apart two places are. */
	public inline function distanceTo(other:Vector):Float {
		return minus(other).length();
	}

	/** How far apart two places are, squared: quicker, and enough to tell which is nearer. */
	public inline function distanceSquaredTo(other:Vector):Float {
		var gap = minus(other);
		return gap.along(gap);
	}
}
