package view;

import shunt.maths.Vector;
import three.Three;

/**
 * Between the simulation's flat ground and three.js's 3D world. The
 * simulation measures east (x) and north (y); three.js has x east, y up,
 * and z towards the viewer, so north is minus z. Turning anticlockwise is
 * the same in both, so a heading carries straight across.
 */
class Placing {
	/** Puts a 3D thing at a spot on the ground, at a height, facing a heading. */
	public static function put(thing:Object3D, spot:Vector, height:Float, heading:Float) {
		thing.position.set(spot.x, height, -spot.y);
		thing.rotation.y = heading;
	}

	/** The x and z three.js uses for a spot on the ground. */
	public static inline function sceneX(spot:Vector):Float {
		return spot.x;
	}

	public static inline function sceneZ(spot:Vector):Float {
		return -spot.y;
	}
}
