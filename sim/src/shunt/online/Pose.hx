package shunt.online;

import shunt.maths.Numbers.wrapAngle;
import shunt.maths.Vector;
import shunt.race.RaceState;

/** Where a car is and which way it points: enough to draw it. */
typedef Pose = {
	final position:Vector;
	final heading:Float;
}

class Poses {
	/** Every car's pose in a race state. */
	public static function of(state:RaceState):Array<Pose> {
		return [for (racer in state.racers) {position: racer.car.position, heading: racer.car.heading}];
	}

	/** A pose moved and turned as another was, from `was` to `now` (a correction carried over). */
	public static function shifted(pose:Pose, was:Pose, now:Pose):Pose {
		return {position: pose.position + (now.position - was.position), heading: pose.heading + wrapAngle(now.heading - was.heading)};
	}

	/** A pose part way from one to another (0: the first, 1: the second), turning the short way round. */
	public static function between(from:Pose, to:Pose, share:Float):Pose {
		return {
			position: from.position + (to.position - from.position) * share,
			heading: from.heading + wrapAngle(to.heading - from.heading) * share
		};
	}
}
