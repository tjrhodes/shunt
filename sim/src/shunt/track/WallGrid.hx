package shunt.track;

import shunt.maths.Vector;

/**
 * A quick way to find the walls near a car without checking every wall on
 * the track. The ground is divided into squares; each square remembers which
 * walls cross it. A car only looks in the squares around it.
 */
class WallGrid {
	/** How wide each square is, in metres. */
	static inline final squareSize = 8.0;

	final walls:Array<Wall>;
	final wallsInSquare = new Map<Int, Array<Int>>();

	public function new(walls:Array<Wall>) {
		this.walls = walls;
		for (wallNumber in 0...walls.length) addToItsSquares(wallNumber);
	}

	/** Every wall that comes within `reach` metres of a spot (and perhaps a few a little further). */
	public function wallsNear(spot:Vector, reach:Float):Array<Wall> {
		var found = new Map<Int, Bool>();
		var near:Array<Wall> = [];
		forEachSquareAround(spot - new Vector(reach, reach), spot + new Vector(reach, reach), square -> {
			for (wallNumber in wallsInSquare.get(square) ?? []) {
				if (!found.exists(wallNumber)) near.push(walls[wallNumber]);
				found.set(wallNumber, true);
			}
		});
		return near;
	}

	/** Notes a wall in every square its bounding box touches. */
	function addToItsSquares(wallNumber:Int) {
		var wall = walls[wallNumber];
		var lowest = new Vector(Math.min(wall.from.x, wall.to.x), Math.min(wall.from.y, wall.to.y));
		var highest = new Vector(Math.max(wall.from.x, wall.to.x), Math.max(wall.from.y, wall.to.y));
		forEachSquareAround(lowest, highest, square -> {
			if (!wallsInSquare.exists(square)) wallsInSquare.set(square, []);
			wallsInSquare.get(square).push(wallNumber);
		});
	}

	/** Visits every square that a box (from its lowest corner to its highest) touches. */
	static function forEachSquareAround(lowest:Vector, highest:Vector, visit:Int -> Void) {
		for (column in squareOf(lowest.x)...squareOf(highest.x) + 1) {
			for (row in squareOf(lowest.y)...squareOf(highest.y) + 1) visit(squareNumber(column, row));
		}
	}

	static function squareOf(metres:Float):Int {
		return Math.floor(metres / squareSize);
	}

	/** One number for a square, from its column and row (fine for tracks up to half a million metres across). */
	static function squareNumber(column:Int, row:Int):Int {
		return column * 65536 + row;
	}
}
