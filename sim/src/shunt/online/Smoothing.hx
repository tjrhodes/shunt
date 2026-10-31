package shunt.online;

import shunt.maths.Numbers.wrapAngle;
import shunt.maths.Vector;

/**
 * Hides a correction from the server (SPEC.md §9): when a car's predicted
 * place jumps, it is drawn where it was and slides to where it should be
 * over a moment, instead of leaping. A huge jump (a crash seen differently)
 * is shown as it is: sliding would look stranger than jumping.
 */
class Smoothing {
	/** How far the car is drawn from where it really is, and turned. */
	var offset = Vector.nothing();
	var turn = 0.0;

	public function new() {}

	/** The car was predicted at `before` and is now put at `after`: draw it from where it was. */
	public function corrected(before:Pose, after:Pose) {
		var jump = before.position - after.position;
		var isTooBig = (offset + jump).length() > OnlineTuning.snapCorrectionsOver;
		offset = isTooBig ? Vector.nothing() : offset + jump;
		turn = isTooBig ? 0 : turn + wrapAngle(before.heading - after.heading);
	}

	/** Where to draw a car that is really at `pose`, with the offset dying away as time passes. */
	public function shown(pose:Pose, secondsPassed:Float):Pose {
		var share = Math.exp(-secondsPassed * 3 / OnlineTuning.correctionEasedOverSeconds);
		offset = offset * share;
		turn *= share;
		return {position: pose.position + offset, heading: pose.heading + turn};
	}
}
