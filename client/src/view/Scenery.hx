package view;

import hud.Words;
import js.Browser;
import shunt.maths.Vector;
import shunt.track.Track;
import three.Three;

/**
 * One side of the rectangle round a track: where it runs from and to, and
 * which way is away from the track.
 */
typedef Side = {
	final from:Vector;
	final to:Vector;
	final outwards:Vector;
}

/**
 * What stands round a track, like the original's: billboards, trees, a
 * crowd in a stand by the start line, and floodlight towers at the corners.
 *
 * It is all placed from the track's own walls, never written down per
 * track: find the rectangle the walls fit inside, then stand everything a
 * little outside it. So nothing can ever stand where the cars race, and a
 * new track gets its scenery for free.
 */
class Scenery {
	/** Billboards stand this far outside the walls' rectangle, one every so many metres along it. */
	static inline final boardsOut = 5.0;
	static inline final boardEvery = 13.0;
	static inline final boardLength = 9.0;
	static inline final boardHeight = 2.2;
	static inline final boardLift = 0.7;

	/** Trees grow further out than the billboards, a few in each gap. */
	static inline final treesOut = 11.0;
	static inline final treeEvery = 6.0;

	/** The stand: this long, with this many rows of seats, each this deep and this much higher. */
	static inline final standLength = 40.0;
	static inline final standRows = 5;
	static inline final rowDeep = 1.6;
	static inline final rowHigher = 0.8;
	static inline final seatEvery = 0.8;

	/** A floodlight tower at each corner, this tall, a bit further out than the boards. */
	static inline final towerHeight = 20.0;
	static inline final towersOut = 8.0;

	public static function build(track:Track):Group {
		var sides = sidesRound(track.wallCorners());
		var standSide = sideNearest(sides, track.sample(0).position);
		var standMiddle = nearestPointOn(standSide, track.sample(0).position);
		var everything = new Group();
		everything.add(billboards(sides, standMiddle));
		everything.add(trees(sides, standMiddle));
		everything.add(stand(standSide, standMiddle));
		everything.add(towers(sides));
		return everything;
	}

	// ---- Where things go ----

	/** The rectangle the walls fit inside, as four sides going anticlockwise round it. */
	static function sidesRound(corners:Array<Vector>):Array<Side> {
		var west = Lambda.fold(corners, (spot, most) -> Math.min(most, spot.x), Math.POSITIVE_INFINITY);
		var east = Lambda.fold(corners, (spot, most) -> Math.max(most, spot.x), Math.NEGATIVE_INFINITY);
		var south = Lambda.fold(corners, (spot, most) -> Math.min(most, spot.y), Math.POSITIVE_INFINITY);
		var north = Lambda.fold(corners, (spot, most) -> Math.max(most, spot.y), Math.NEGATIVE_INFINITY);
		return [
			{from: new Vector(west, south), to: new Vector(east, south), outwards: new Vector(0, -1)},
			{from: new Vector(east, south), to: new Vector(east, north), outwards: new Vector(1, 0)},
			{from: new Vector(east, north), to: new Vector(west, north), outwards: new Vector(0, 1)},
			{from: new Vector(west, north), to: new Vector(west, south), outwards: new Vector(-1, 0)}
		];
	}

	/** Spots every so many metres along a side, pushed out from it by a distance. */
	static function spotsAlong(side:Side, every:Float, out:Float):Array<Vector> {
		var along = side.to - side.from;
		var count = Math.floor(along.length() / every);
		var gap = along.length() / Math.max(1, count);
		var startsAt = side.from + side.outwards * out;
		return [for (step in 0...count + 1) startsAt + along.lengthOne() * (step * gap)];
	}

	/** The side the start line is nearest: the crowd wants to see the start. */
	static function sideNearest(sides:Array<Side>, spot:Vector):Side {
		var nearest = sides[0];
		for (side in sides) if (nearestPointOn(side, spot).distanceTo(spot) < nearestPointOn(nearest, spot).distanceTo(spot)) nearest = side;
		return nearest;
	}

	static function nearestPointOn(side:Side, spot:Vector):Vector {
		return shunt.track.Wall.Walls.nearestPointTo({from: side.from, to: side.to, endsThatStickOut: []}, spot);
	}

	/** A number between 0 and 1 that looks random but is always the same for the same seed, so the scenery never shuffles. */
	static function wobble(seed:Float):Float {
		var big = Math.sin(seed * 12.9898) * 43758.5453;
		return big - Math.floor(big);
	}

	// ---- Billboards ----

	/** A billboard every so often along each side, facing the track, leaving room for the stand. */
	static function billboards(sides:Array<Side>, standMiddle:Vector):Group {
		var boards = new Group();
		var faces = [for (index in 0...Words.billboards.length) boardFace(index)];
		var shape = new BoxGeometry(boardLength, boardHeight, 0.3);
		var count = 0;
		for (side in sides) for (spot in spotsAlong(side, boardEvery, boardsOut)) {
			if (spot.distanceTo(standMiddle) < standLength / 2 + boardsOut + boardLength) continue;
			boards.add(board(shape, faces[count++ % faces.length], spot, side));
		}
		return boards;
	}

	static function board(shape:BufferGeometry, face:Material, spot:Vector, side:Side):Mesh {
		var board = new Mesh(shape, face);
		Placing.put(board, spot, boardLift + boardHeight / 2, (side.to - side.from).angle());
		board.castShadow = true;
		return board;
	}

	/** One sponsor's board: its made-up name in white on its colour. */
	static function boardFace(index:Int):Material {
		var canvas = Browser.document.createCanvasElement();
		canvas.width = 512;
		canvas.height = 128;
		var paint = canvas.getContext2d();
		paint.fillStyle = Paint.css(Paint.billboards[index % Paint.billboards.length]);
		paint.fillRect(0, 0, 512, 128);
		paint.fillStyle = Paint.css(Paint.billboardWords);
		paint.font = "800 84px 'Saira Condensed', sans-serif";
		paint.textAlign = "center";
		paint.textBaseline = "middle";
		paint.fillText(Words.billboards[index], 256, 68, 472);
		return new MeshBasicMaterial({map: new CanvasTexture(canvas)});
	}

	// ---- Trees ----

	/** Trees along every side, beyond the billboards (but not behind the stand), each a little off the line and a different size. */
	static function trees(sides:Array<Side>, standMiddle:Vector):Group {
		var spots = [for (side in sides) for (spot in spotsAlong(side, treeEvery, treesOut)) if (spot.distanceTo(standMiddle) > standLength / 2 + treesOut) spot + side.outwards * (wobble(spot.x + spot.y) * 6)];
		var leaves = new InstancedMesh(new ConeGeometry(2.2, 6, 7), new MeshLambertMaterial({color: Paint.leaves}), spots.length);
		var trunks = new InstancedMesh(new BoxGeometry(0.5, 1.6, 0.5), new MeshLambertMaterial({color: Paint.trunk}), spots.length);
		var placer = new Object3D();
		for (index in 0...spots.length) {
			var size = 0.7 + 0.6 * wobble(index);
			placeScaled(leaves, index, placer, spots[index], 1.4 + 3 * size, size);
			placeScaled(trunks, index, placer, spots[index], 0.8, 1);
		}
		var group = new Group();
		group.add(leaves);
		group.add(trunks);
		return group;
	}

	/** One of an instanced mesh's copies, put at a spot and height, at a size. */
	static function placeScaled(copies:InstancedMesh, index:Int, placer:Object3D, spot:Vector, height:Float, size:Float) {
		Placing.put(placer, spot, height, 0);
		placer.scale.set(size, size, size);
		placer.updateMatrix();
		copies.setMatrixAt(index, placer.matrix);
		copies.castShadow = true;
	}

	// ---- The stand ----

	/** Rows of seats stepping up and away from the track, full of people in every colour. */
	static function stand(side:Side, middle:Vector):Group {
		var stand = new Group();
		var heading = (side.to - side.from).angle();
		for (row in 0...standRows) {
			var step = new Mesh(new BoxGeometry(standLength, rowHigher * (row + 1), rowDeep), new MeshLambertMaterial({color: Paint.standConcrete}));
			Placing.put(step, rowSpot(side, middle, row), rowHigher * (row + 1) / 2, heading);
			step.receiveShadow = true;
			stand.add(step);
		}
		stand.add(crowd(side, middle, heading));
		return stand;
	}

	/** Where a row of the stand stands: the first by the boards, each next one further back. */
	static function rowSpot(side:Side, middle:Vector, row:Int):Vector {
		return middle + side.outwards * (boardsOut + rowDeep * row);
	}

	/** A person in each seat (a little box), each in a colour of the crowd. */
	static function crowd(side:Side, middle:Vector, heading:Float):InstancedMesh {
		var seatsInARow = Math.floor(standLength / seatEvery);
		var people = new InstancedMesh(new BoxGeometry(0.45, 0.7, 0.4), new MeshLambertMaterial({color: 0xffffff}), seatsInARow * standRows);
		var along = (side.to - side.from).lengthOne();
		var placer = new Object3D();
		for (row in 0...standRows) for (seat in 0...seatsInARow) {
			var index = row * seatsInARow + seat;
			var spot = rowSpot(side, middle, row) + along * ((seat + 0.5) * seatEvery - standLength / 2);
			placeScaled(people, index, placer, spot, rowHigher * (row + 1) + 0.35, 1);
			people.setColorAt(index, new Color(Paint.crowd[Math.floor(wobble(index) * Paint.crowd.length)]));
		}
		return people;
	}

	// ---- Floodlight towers ----

	/** A tall mast with a bank of lamps on top at every corner of the rectangle, a little way out. */
	static function towers(sides:Array<Side>):Group {
		var towers = new Group();
		for (side in sides) {
			var alongTheSide = (side.to - side.from).lengthOne();
			towers.add(tower(side.from + (side.outwards - alongTheSide) * towersOut, alongTheSide.angle() + Math.PI / 4));
		}
		return towers;
	}

	/** One tower at a spot, its lamps turned to face the track. */
	static function tower(spot:Vector, lampsFacing:Float):Group {
		var tower = new Group();
		var pole = new Mesh(new BoxGeometry(0.6, towerHeight, 0.6), new MeshLambertMaterial({color: Paint.towerSteel}));
		Placing.put(pole, spot, towerHeight / 2, 0);
		pole.castShadow = true;
		var lamps = new Mesh(new BoxGeometry(3, 1.6, 0.6), new MeshBasicMaterial({color: Paint.floodlight}));
		Placing.put(lamps, spot, towerHeight, lampsFacing);
		tower.add(pole);
		tower.add(lamps);
		return tower;
	}
}
