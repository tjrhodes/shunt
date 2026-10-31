package shunt.online;

import shunt.online.Pose;

/** Everyone's pose in a snapshot, and when it arrived (seconds). */
typedef TimedPoses = {
	final at:Float;
	final poses:Array<Pose>;
}

/**
 * Other people's cars, drawn a little in the past (SPEC.md §9): snapshots
 * arrive 30 times a second, and not evenly, so a car is drawn part way
 * between the two snapshots either side of "a tenth of a second ago". It
 * then moves as smoothly as the cars this browser drives.
 */
class ShownBehind {
	final kept:Array<TimedPoses> = [];

	public function new() {}

	/** A snapshot's poses arrived at a time. */
	public function arrived(at:Float, poses:Array<Pose>) {
		kept.push({at: at, poses: poses});
		while (kept.length > 2 && kept[1].at < at - 1) kept.shift();
	}

	/** A seat's pose as it was a little before `now`: between the snapshots either side, or the nearest one. */
	public function poseOf(seat:Int, now:Float):Null<Pose> {
		if (kept.length == 0) return null;
		var showing = now - OnlineTuning.othersShownSecondsBehind;
		var after = 0;
		while (after < kept.length - 1 && kept[after].at < showing) after++;
		if (after == 0) return kept[0].poses[seat];
		var before = kept[after - 1];
		var share = Math.min(1, (showing - before.at) / Math.max(1e-6, kept[after].at - before.at));
		return Poses.between(before.poses[seat], kept[after].poses[seat], share);
	}

	/** Forgets everything (a new race). */
	public function clear() {
		kept.resize(0);
	}
}
