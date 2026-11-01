package view;

import shunt.contact.ContactTuning;
import shunt.track.Track;
import shunt.track.Wall;
import three.Three;

/**
 * The track in 3D, built from the very same `Track` the race runs on: the
 * grass, the asphalt (between a road's edges, or an arena's whole floor),
 * every wall piece, the start line, and the scenery round it all. Nothing about its shape is written
 * again here.
 */
class TrackView {
	/** How tall the walls are, in metres. */
	static inline final wallHeight = 1.3;

	/** How much bigger than the track the grass reaches. */
	static inline final grassBeyondTheTrack = 3000.0;

	/** Walls are drawn as blocks at most this long, coloured in turn. */
	static inline final blockLength = 3.0;

	/** The start line's squares are this big. */
	static inline final checkSize = 0.8;

	/** Lifts the asphalt and line a hair above the grass, so they don't flicker into it. */
	static inline final aboveTheGrass = 0.02;

	public static function build(track:Track):Group {
		var everything = new Group();
		everything.add(grass());
		everything.add(track.isARoad ? asphalt(track) : arenaFloor(track));
		everything.add(walls(track.walls));
		everything.add(startLine(track));
		everything.add(Scenery.build(track));
		return everything;
	}

	static function grass():Mesh {
		var ground = new Mesh(new PlaneGeometry(grassBeyondTheTrack, grassBeyondTheTrack).rotateX(-Math.PI / 2), new MeshLambertMaterial({color: Paint.grass}));
		ground.receiveShadow = true;
		return ground;
	}

	/**
	 * A ribbon of asphalt between the left and right edges: for each sample,
	 * a corner on each edge; between one sample and the next, two triangles.
	 */
	static function asphalt(track:Track):Mesh {
		var corners:Array<Float> = [];
		for (index in 0...track.samples.length) {
			for (side in [1, -1]) {
				var edge = track.edgeAt(index, side);
				corners.push(Placing.sceneX(edge));
				corners.push(aboveTheGrass);
				corners.push(Placing.sceneZ(edge));
			}
		}
		var ribbon = new Mesh(shapeFrom(corners, trianglesRound(track.samples.length)), new MeshLambertMaterial({color: Paint.asphalt}));
		ribbon.receiveShadow = true;
		return ribbon;
	}

	/** An arena's floor: its outline, filled with asphalt. */
	static function arenaFloor(track:Track):Mesh {
		var outline = new Shape();
		outline.moveTo(track.arenaOutline[0].x, track.arenaOutline[0].y);
		for (corner in track.arenaOutline.slice(1)) outline.lineTo(corner.x, corner.y);
		var flatOnTheGround = new ShapeGeometry(outline).rotateX(-Math.PI / 2).translate(0, aboveTheGrass, 0);
		var floor = new Mesh(flatOnTheGround, new MeshLambertMaterial({color: Paint.asphalt}));
		floor.receiveShadow = true;
		return floor;
	}

	/**
	 * Two triangles between each pair of samples, joining the last back to
	 * the first. Corner `2i` is sample i's left edge and `2i + 1` its right.
	 * The corners go round anticlockwise seen from above, so the asphalt
	 * faces up to the lights.
	 */
	static function trianglesRound(sampleCount:Int):Array<Int> {
		var triangles:Array<Int> = [];
		for (index in 0...sampleCount) {
			var left = index * 2;
			var nextLeft = ((index + 1) % sampleCount) * 2;
			for (corner in [left, left + 1, nextLeft, left + 1, nextLeft + 1, nextLeft]) triangles.push(corner);
		}
		return triangles;
	}

	static function shapeFrom(corners:Array<Float>, triangles:Array<Int>):BufferGeometry {
		var shape = new BufferGeometry();
		shape.setAttribute("position", new Float32BufferAttribute(corners, 3));
		shape.setIndex(triangles);
		shape.computeVertexNormals();
		return shape;
	}

	/**
	 * The walls as blocks no longer than a few metres, painted concrete and
	 * red in turn like a real barrier (it shows which way a wall runs, and
	 * how fast you pass it). All drawn at once: an "instanced" mesh, each
	 * block stretched and turned to fit.
	 */
	static function walls(pieces:Array<Wall>):InstancedMesh {
		var thickness = 2 * ContactTuning.wallHalfThickness;
		var stretches = [for (wall in pieces) for (stretch in blocksAlong(wall)) stretch];
		var blocks = new InstancedMesh(new BoxGeometry(1, wallHeight, thickness), new MeshLambertMaterial({color: 0xffffff}), stretches.length);
		var placer = new Object3D();
		for (index in 0...stretches.length) {
			fitBlockToWall(placer, stretches[index], thickness);
			blocks.setMatrixAt(index, placer.matrix);
			blocks.setColorAt(index, new Color(index % 2 == 0 ? Paint.concrete : Paint.barrierStripe));
		}
		blocks.castShadow = true;
		blocks.receiveShadow = true;
		return blocks;
	}

	/** A wall cut into equal blocks no longer than `blockLength`, each a little wall of its own. */
	static function blocksAlong(wall:Wall):Array<Wall> {
		var along = wall.to - wall.from;
		var count = Math.ceil(along.length() / blockLength);
		var step = along * (1 / count);
		return [for (block in 0...count) {from: wall.from + step * block, to: wall.from + step * (block + 1), endsThatStickOut: []}];
	}

	/** Moves, turns and stretches a block to cover a wall piece, a little longer so the joints close. */
	static function fitBlockToWall(block:Object3D, wall:Wall, thickness:Float) {
		var along = wall.to - wall.from;
		Placing.put(block, wall.from + along * 0.5, wallHeight / 2, along.angle());
		block.scale.set(along.length() + thickness, 1, 1);
		block.updateMatrix();
	}

	/** A chequered band across the track where the lap starts: squares in two rows, black and white in turn. */
	static function startLine(track:Track):InstancedMesh {
		var here = track.sample(0);
		var across = Math.round(here.width / checkSize);
		var squares = new InstancedMesh(new BoxGeometry(checkSize, 0.02, checkSize), new MeshLambertMaterial({color: 0xffffff}), across * 2);
		var placer = new Object3D();
		for (row in 0...2) for (column in 0...across) {
			var index = row * across + column;
			var spot = here.position + here.direction * ((row - 0.5) * checkSize) + here.direction.turnedLeft() * ((column + 0.5) * checkSize - here.width / 2);
			Placing.put(placer, spot, aboveTheGrass * 2, here.direction.angle());
			placer.updateMatrix();
			squares.setMatrixAt(index, placer.matrix);
			squares.setColorAt(index, new Color((row + column) % 2 == 0 ? Paint.startLine : Paint.chequerDark));
		}
		return squares;
	}
}
