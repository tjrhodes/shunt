package shunt.track;

/** A point placed by hand on a track's centreline, with how wide the track is there (metres). */
typedef TrackPoint = {
	final x:Float;
	final y:Float;
	final width:Float;
}

/** A corner of a free-standing wall. */
typedef BarrierPoint = {
	final x:Float;
	final y:Float;
}

/**
 * What a track's JSON file holds (SPEC.md §5): its name, a few points round
 * its centreline (smoothed into a curve when loaded), and any free-standing
 * walls. Everything else (edge walls, the grid, checkpoints, how fast each
 * bend can be taken) is worked out from these, so it is written nowhere.
 * The centreline goes the way the race goes, starting at the start line.
 */
typedef TrackFile = {
	final name:String;
	final centreline:Array<TrackPoint>;
	final barriers:Array<Array<BarrierPoint>>;
}
