package shunt.car;

import shunt.maths.Vector;

/**
 * What one source of force does to a car during a tick: a push that moves
 * it (newtons, in world directions) and a twist that turns it
 * (newton-metres, anticlockwise). Tyres, engine and air each give one, and
 * they are added up before the car moves.
 */
class Push {
	public final force:Vector;
	public final twist:Float;

	public function new(force:Vector, twist:Float) {
		this.force = force;
		this.twist = twist;
	}

	/** No push and no twist. */
	public static function nothing():Push {
		return new Push(Vector.nothing(), 0);
	}

	/** A push straight through the centre of mass, so it moves the car without turning it. */
	public static function straight(force:Vector):Push {
		return new Push(force, 0);
	}

	/** This push and another, together. */
	public function plus(other:Push):Push {
		return new Push(force + other.force, twist + other.twist);
	}

	/** This push, made weaker or stronger. */
	public function times(amount:Float):Push {
		return new Push(force * amount, twist * amount);
	}
}
