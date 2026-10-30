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

	/** Walls joining a list of places one after another (and back to the start, if `closed`). */
	public static function joining(places:Array<Vector>, closed:Bool):Array<Wall> {
		var pieces = closed ? places.length : places.length - 1;
		return [for (i in 0...pieces) {from: places[i], to: places[(i + 1) % places.length]}];
	}
}
