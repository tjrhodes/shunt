package shunt.contact;

import shunt.car.Car;
import shunt.contact.ContactTuning as Tuning;
import shunt.maths.Vector;
import shunt.track.Track;
import shunt.track.Wall;
import shunt.track.Wall.Walls;

/**
 * Where a car touches walls. Two kinds of touch: a corner of the car against
 * a wall's face, and an end of a wall that sticks out (a barrier's tip, or a
 * sharp corner) poking into the side of the car.
 */
class WallContacts {
	/** Every place a car touches a wall, each with the way to push the car off it. */
	public static function of(car:Car, track:Track):Array<Contact> {
		var nearbyWalls = track.wallsNear(car.position, CarShape.reach + Tuning.wallHalfThickness);
		var touches:Array<Contact> = [];
		for (wall in nearbyWalls) {
			for (corner in CarShape.corners(car)) addIfTouching(touches, cornerAgainstWall(corner, wall));
			for (end in wall.endsThatStickOut) addIfTouching(touches, wallEndInCar(car, end));
		}
		return touches;
	}

	/** A corner of the car closer to a wall's middle line than the wall's face: pushed straight out from the wall. */
	static function cornerAgainstWall(corner:Vector, wall:Wall):Null<Contact> {
		var nearestOnWall = Walls.nearestPointTo(wall, corner);
		var gap = corner.distanceTo(nearestOnWall);
		if (gap >= Tuning.wallHalfThickness || gap == 0) return null;
		var awayFromWall = (corner - nearestOnWall).lengthOne();
		return {point: corner, pushFirstAway: awayFromWall, overlap: Tuning.wallHalfThickness - gap};
	}

	/** A wall's end inside the car: the car is pushed off it, the opposite way to the end leaving the car. */
	static function wallEndInCar(car:Car, end:Vector):Null<Contact> {
		var endLeaving = CarShape.pointInside(car, end, Tuning.wallHalfThickness);
		if (endLeaving == null) return null;
		return {point: end, pushFirstAway: endLeaving.pushFirstAway * -1, overlap: endLeaving.overlap};
	}

	static function addIfTouching(touches:Array<Contact>, touch:Null<Contact>) {
		if (touch != null) touches.push(touch);
	}
}
