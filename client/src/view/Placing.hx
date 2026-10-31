package view;

import shunt.maths.Vector;
import three.Three;

/** A point in three.js's world (y is up), or a speed in it. */
typedef Point3 = {
	final x:Float;
	final y:Float;
	final z:Float;
}

/**
 * Between the simulation's flat ground and three.js's 3D world. The
 * simulation measures east (x) and north (y); three.js has x east, y up,
 * and z towards the viewer, so north is minus z. Turning anticlockwise is
 * the same in both, so a heading carries straight across.
 */
class Placing {
	/** Puts a 3D thing at a spot on the ground, at a height, facing a heading. */
	public static function put(thing:Object3D, spot:Vector, height:Float, heading:Float) {
		thing.position.set(sceneX(spot), height, sceneZ(spot));
		thing.rotation.y = heading;
	}

	/** A spot on the ground, at a height, as a point in three.js's world. */
	public static inline function above(spot:Vector, height:Float):Point3 {
		return {x: sceneX(spot), y: height, z: sceneZ(spot)};
	}

	/** The x and z three.js uses for a spot on the ground. */
	public static inline function sceneX(spot:Vector):Float {
		return spot.x;
	}

	public static inline function sceneZ(spot:Vector):Float {
		return -spot.y;
	}
}
