package shunt.track;

import haxe.Json;
import shunt.maths.Vector;
import shunt.track.Centreline.CentrePlace;
import shunt.track.TrackFile.BarrierPoint;
import shunt.race.RaceTuning;
import shunt.track.Wall.Walls;

/** One place on the smoothed centreline, about a metre from the next. */
typedef TrackSample = {
	/** Where it is. */
	final position:Vector;

	/** Which way the race goes here (an arrow one long). */
	final direction:Vector;

	/** How wide the track is here, wall to wall. */
	final width:Float;

	/** How far round the lap from the start line, in metres. */
	final distance:Float;

	/** How sharply the track bends here: one over the radius of the bend (0 on a straight). */
	final bendiness:Float;
}

/**
 * A track, ready to race on: its smoothed centreline, its walls and a quick
 * way to find the walls near a spot. Made once from a track file, and never
 * changed, so it is not part of the race's state.
 */
class Track {
	/** About how far apart the centreline samples are, in metres. */
	public static inline final sampleSpacing = 1.0;

	/** How many centreline samples apart the edge walls' corners are (fewer walls, same shape). */
	static inline final samplesPerEdgeWall = 2;

	public final name:String;
	public final samples:Array<TrackSample>;
	public final length:Float;
	public final laps:Int;
	public final walls:Array<Wall>;

	/** A road has walls down its edges; an arena is an open floor inside its outline (see `TrackFile`). */
	public final isARoad:Bool;

	/** An arena's outline, which is also its floor; empty for a road. */
	public final arenaOutline:Array<Vector>;

	final wallGrid:WallGrid;

	public function new(file:TrackFile) {
		name = file.name;
		var places = Centreline.evenlySpaced(file.centreline, sampleSpacing);
		length = loopLength(places);
		samples = [for (index in 0...places.length) sampleAt(places, index, length)];
		laps = file.laps ?? RaceTuning.defaultLaps;
		isARoad = file.edgeWalls ?? true;
		var loops = [for (loop in file.loops ?? []) spotsOf(loop)];
		arenaOutline = isARoad || loops.length == 0 ? [] : loops[0];
		walls = (isARoad ? edgeWalls() : []).concat(loopWalls(loops)).concat(barrierWalls(file.barriers));
		wallGrid = new WallGrid(walls);
	}

	/** A track from the text of its JSON file. */
	public static function fromJson(text:String):Track {
		return new Track(Json.parse(text));
	}

	/** The sample at an index, counting round and round the loop (so -1 is the last one). */
	public function sample(index:Int):TrackSample {
		var count = samples.length;
		return samples[((index % count) + count) % count];
	}

	/** An arrow one long pointing to the left of the race direction at a sample. */
	public function leftAt(index:Int):Vector {
		return sample(index).direction.turnedLeft();
	}

	/** Where the left or right edge is at a sample (`side` 1 for left, -1 for right). */
	public function edgeAt(index:Int, side:Float):Vector {
		var here = sample(index);
		return here.position + leftAt(index) * (side * here.width / 2);
	}

	/** How far to the left of the centreline a spot is, measured at a sample (negative is to the right). */
	public function howFarLeft(spot:Vector, index:Int):Float {
		return (spot - sample(index).position).along(leftAt(index));
	}

	/**
	 * The sample nearest a spot, looking only within `reach` samples of a
	 * sample it was near before. Looking only nearby means a car can't jump
	 * to another part of the track that happens to pass close by.
	 */
	public function nearestSampleNear(spot:Vector, before:Int, reach:Int):Int {
		var nearest = before;
		for (offset in -reach...reach + 1) {
			var index = (before + offset + samples.length) % samples.length;
			if (isNearer(spot, index, nearest)) nearest = index;
		}
		return nearest;
	}

	/** The sample nearest a spot, looking all the way round. */
	public function nearestSample(spot:Vector):Int {
		var nearest = 0;
		for (index in 1...samples.length) if (isNearer(spot, index, nearest)) nearest = index;
		return nearest;
	}

	function isNearer(spot:Vector, index:Int, thanIndex:Int):Bool {
		return spot.distanceSquaredTo(samples[index].position) < spot.distanceSquaredTo(samples[thanIndex].position);
	}

	/** Every wall within `reach` metres of a spot (and perhaps a few a little further). */
	public function wallsNear(spot:Vector, reach:Float):Array<Wall> {
		return wallGrid.wallsNear(spot, reach);
	}

	/** The sample a number of metres back from the start line. */
	public function sampleIndexBehindTheLine(metres:Float):Int {
		var samplesBack = Math.round(metres / (length / samples.length));
		return (samples.length - samplesBack % samples.length) % samples.length;
	}

	// ---- Building the track ----

	static function loopLength(places:Array<CentrePlace>):Float {
		var total = 0.0;
		for (index in 0...places.length) total += places[index].position.distanceTo(places[(index + 1) % places.length].position);
		return total;
	}

	/** A sample, with its direction and bendiness worked out from its neighbours. */
	static function sampleAt(places:Array<CentrePlace>, index:Int, loopLength:Float):TrackSample {
		var count = places.length;
		var before = places[(index - 1 + count) % count].position;
		var here = places[index];
		var after = places[(index + 1) % count].position;
		return {
			position: here.position,
			direction: (after - before).lengthOne(),
			width: here.width,
			distance: index * loopLength / count,
			bendiness: bendinessThrough(before, here.position, after)
		};
	}

	/** How sharply a path turns through three places: how much it turns, divided by how far it goes. */
	static function bendinessThrough(before:Vector, here:Vector, after:Vector):Float {
		var into = here - before;
		var outOf = after - here;
		var turn = Math.atan2(into.turning(outOf), into.along(outOf));
		return Math.abs(turn) / ((into.length() + outOf.length()) / 2);
	}

	/** The walls down both edges of the track, made from the same centreline samples. */
	function edgeWalls():Array<Wall> {
		var corners = [for (index in 0...samples.length) if (index % samplesPerEdgeWall == 0) index];
		var leftEdge = Walls.joining([for (index in corners) edgeAt(index, 1)], true);
		var rightEdge = Walls.joining([for (index in corners) edgeAt(index, -1)], true);
		return leftEdge.concat(rightEdge);
	}

	/** The free-standing walls, each a line from corner to corner. */
	static function barrierWalls(barriers:Array<Array<BarrierPoint>>):Array<Wall> {
		var walls:Array<Wall> = [];
		for (corners in barriers) walls = walls.concat(Walls.joining(spotsOf(corners), false));
		return walls;
	}

	/** The closed wall loops, each joined back to its start. */
	static function loopWalls(loops:Array<Array<Vector>>):Array<Wall> {
		var walls:Array<Wall> = [];
		for (loop in loops) walls = walls.concat(Walls.joining(loop, true));
		return walls;
	}

	static function spotsOf(corners:Array<BarrierPoint>):Array<Vector> {
		return [for (corner in corners) new Vector(corner.x, corner.y)];
	}

	/** Every place a wall starts: enough to see how far the track reaches, whatever its kind. */
	public function wallCorners():Array<Vector> {
		return [for (wall in walls) wall.from].concat([for (wall in walls) wall.to]);
	}
}
