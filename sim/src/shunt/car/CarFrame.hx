package shunt.car;

import shunt.maths.Vector;

/**
 * Seeing the world from the driver's seat. Tyres and engines only care about
 * "forwards" and "sideways" for the car, not north and east, so these turn
 * one into the other.
 *
 * Used as `using CarFrame`, so code reads `car.forwardSpeed()`.
 */
class CarFrame {
	/** An arrow one long, pointing out of the car's nose. */
	public static inline function noseDirection(car:Car):Vector {
		return Vector.pointingAt(car.heading);
	}

	/** An arrow one long, pointing out of the driver's left window. */
	public static inline function leftDirection(car:Car):Vector {
		return noseDirection(car).turnedLeft();
	}

	/** How fast the car is going forwards (negative when reversing). */
	public static inline function forwardSpeed(car:Car):Float {
		return car.velocity.along(noseDirection(car));
	}

	/** How fast the car is sliding to its left (negative when sliding right). */
	public static inline function sidewaysSpeed(car:Car):Float {
		return car.velocity.along(leftDirection(car));
	}

	/** How fast the car is going, whichever way. */
	public static inline function speed(car:Car):Float {
		return car.velocity.length();
	}

	/** An arrow given in the car's own terms (x forwards, y to the left), turned to face the world's way. */
	public static inline function inWorldTerms(car:Car, inCarTerms:Vector):Vector {
		return noseDirection(car) * inCarTerms.x + leftDirection(car) * inCarTerms.y;
	}

	/** The other way round: an arrow in the world's terms, as the car sees it (x forwards, y to the left). */
	public static inline function inCarTerms(car:Car, inWorldTerms:Vector):Vector {
		return new Vector(inWorldTerms.along(noseDirection(car)), inWorldTerms.along(leftDirection(car)));
	}

	/** The spot on the ground under a point of the car, given in the car's terms. */
	public static inline function spotUnder(car:Car, inCarTerms:Vector):Vector {
		return car.position + inWorldTerms(car, inCarTerms);
	}
}
