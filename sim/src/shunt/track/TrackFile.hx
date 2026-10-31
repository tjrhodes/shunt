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
 * its centreline (smoothed into a curve when loaded), and any walls of its
 * own. Everything else (the grid, checkpoints, how fast each bend can be
 * taken) is worked out from these, so it is written nowhere. The centreline
 * goes the way the race goes, starting at the start line.
 *
 * There are two kinds of track. A *road* (the oval) has walls down both
 * edges, built from the centreline and its width. An *arena* (a maze) is an
 * open floor inside a wall loop, with fences making the course; its
 * centreline only guides laps, putting cars back, and the AI.
 */
typedef TrackFile = {
	final name:String;
	final centreline:Array<TrackPoint>;

	/** Free-standing walls, each a line from corner to corner, not closed. */
	final barriers:Array<Array<BarrierPoint>>;

	/** Closed wall loops; on an arena the first is its outline, and its floor. */
	final ?loops:Array<Array<BarrierPoint>>;

	/** Whether to build walls down both edges of the centreline. Yes, unless it says no (an arena does). */
	final ?edgeWalls:Bool;

	/** How many laps a race here is, if not the usual (`RaceTuning.defaultLaps`). */
	final ?laps:Int;
}
