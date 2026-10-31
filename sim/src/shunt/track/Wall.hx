package shunt.track;

import shunt.maths.Numbers.keepBetween;
import shunt.maths.Vector;

/**
 * One straight piece of wall, from one place to another. Edge walls and
 * free-standing barriers are both made of these, and the physics treats
 * them all alike.
 */
typedef Wall = {
	final from:Vector;
	final to:Vector;

	/**
	 * Its ends that stick out, and so can poke into the side of a car: the
	 * free tip of a barrier, or a sharp corner (the bend of an L). A joint
	 * where a wall carries on smoothly is not one: a car slides past it.
	 */
	final endsThatStickOut:Array<Vector>;
}

class Walls {
	/** The place on a wall nearest to a spot. */
	public static function nearestPointTo(wall:Wall, spot:Vector):Vector {
		var along = wall.to - wall.from;
		var lengthSquared = along.along(along);
		if (lengthSquared == 0) return wall.from;
		var shareOfTheWay = keepBetween((spot - wall.from).along(along) / lengthSquared, 0, 1);
		return wall.from + along * shareOfTheWay;
	}

	/** A wall turning by more than this (radians) where two pieces meet has a corner that sticks out. */
	static final sharpTurn = Math.PI / 6;

	/** Walls joining a list of places one after another (and back to the start, if `closed`). */
	public static function joining(places:Array<Vector>, closed:Bool):Array<Wall> {
		var pieces = closed ? places.length : places.length - 1;
		return [for (i in 0...pieces) pieceBetween(places, i, (i + 1) % places.length, closed)];
	}

	static function pieceBetween(places:Array<Vector>, first:Int, second:Int, closed:Bool):Wall {
		var ends = [first, second].filter(index -> sticksOut(places, index, closed));
		return {from: places[first], to: places[second], endsThatStickOut: [for (index in ends) places[index]]};
	}

	/** Whether the wall's place at an index sticks out: a free end, or where the wall turns sharply. */
	static function sticksOut(places:Array<Vector>, index:Int, closed:Bool):Bool {
		var count = places.length;
		if (!closed && (index == 0 || index == count - 1)) return true;
		var comingIn = places[index] - places[(index - 1 + count) % count];
		var goingOut = places[(index + 1) % count] - places[index];
		return Math.abs(Math.atan2(comingIn.turning(goingOut), comingIn.along(goingOut))) > sharpTurn;
	}
}
