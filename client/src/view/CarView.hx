package view;

import js.Browser;
import shunt.car.Car;
import shunt.car.CarTuning;
import three.Three;
import view.Paint.Livery;

/**
 * One car in 3D: a low-poly stock car built from boxes to the simulation's
 * own size, in its livery, with its number on the roof. The front wheels
 * turn as the car's wheels do, and hits dent the body (drawn only: the
 * simulation's damage zones are what count, SPEC.md §10).
 */
class CarView {
	static inline final bodyHeight = 0.75;
	static inline final rideHeight = 0.2;
	static inline final cabinLength = 2.2;
	static inline final cabinHeight = 0.55;
	static inline final wheelSize = 0.7;
	static inline final wheelWidth = 0.32;

	/** The body is built of this many pieces along, up and across, so a dent has corners to push in. */
	static inline final piecesAlong = 10;
	static inline final piecesUp = 2;
	static inline final piecesAcross = 4;

	/** A dent reaches this far (metres) round the point of a hit... */
	static inline final dentReach = 1.1;

	/** ...and goes in this far for each m/s the hit changed the car's speed, up to the most. */
	static inline final dentPerSpeedChange = 0.025;
	static inline final deepestDent = 0.32;

	public final whole = new Group();
	final frontWheels:Array<Mesh> = [];
	final body:Mesh;
	final bodyUndented:Array<Float>;

	public function new(livery:Livery) {
		var bodyShape = new BoxGeometry(CarTuning.length, bodyHeight, CarTuning.width, piecesAlong, piecesUp, piecesAcross);
		body = shadowed(new Mesh(bodyShape, new MeshLambertMaterial({color: livery.colour})), rideHeight + bodyHeight / 2, 0);
		bodyUndented = [for (number in bodyShape.attributes.position.array) number];
		whole.add(body);
		whole.add(shadowed(new Mesh(new BoxGeometry(cabinLength, cabinHeight, CarTuning.width * 0.84), new MeshLambertMaterial({color: Paint.glass})), roofHeight() - cabinHeight / 2, -0.3));
		whole.add(roofNumber(livery));
		for (axle in [CarTuning.frontAxleAhead, -CarTuning.rearAxleBehind]) addWheels(axle);
	}

	/** Moves the car to where the simulation has it (between two ticks, for smoothness). */
	public function show(car:Car, heading:Float, position:shunt.maths.Vector) {
		Placing.put(whole, position, 0, heading);
		for (wheel in frontWheels) wheel.rotation.y = -car.wheelAngle;
	}

	/**
	 * A hit at a point (in the car's terms: x forwards, y to the left)
	 * dents the body there: corners near it are pushed in, most at the
	 * point and less further away; into the end or the side, whichever the
	 * point is nearer.
	 */
	public function dent(hitInCarTerms:shunt.maths.Vector, speedChange:Float) {
		var depth = Math.min(deepestDent, speedChange * dentPerSpeedChange);
		var corners = body.geometry.attributes.position;
		var endOn = Math.abs(hitInCarTerms.x) / CarTuning.length > Math.abs(hitInCarTerms.y) / CarTuning.width;
		for (corner in 0...corners.count) pushCornerIn(corners.array, corner, hitInCarTerms, depth, endOn);
		corners.needsUpdate = true;
		body.geometry.computeVertexNormals();
	}

	/** Takes every dent out (a new race). */
	public function mendDents() {
		var corners = body.geometry.attributes.position;
		for (index in 0...bodyUndented.length) corners.array[index] = bodyUndented[index];
		corners.needsUpdate = true;
		body.geometry.computeVertexNormals();
	}

	/**
	 * One corner of the body pushed in, if it is near the hit. The body's
	 * own x runs forwards and its z to the right (three.js's way), so the
	 * car's "left" is minus z.
	 */
	static function pushCornerIn(numbers:js.lib.Float32Array, corner:Int, hit:shunt.maths.Vector, depth:Float, endOn:Bool) {
		var x = corner * 3;
		var z = corner * 3 + 2;
		var distance = Math.sqrt(Math.pow(numbers[x] - hit.x, 2) + Math.pow(numbers[z] + hit.y, 2));
		if (distance >= dentReach) return;
		var push = depth * (1 - distance / dentReach);
		var axis = endOn ? x : z;
		numbers[axis] -= (numbers[axis] > 0 ? 1 : -1) * push;
	}

	static function roofHeight():Float {
		return rideHeight + bodyHeight + cabinHeight;
	}

	/** A pair of wheels on an axle, at the car's sides. The front pair are remembered, to steer. */
	function addWheels(howFarAhead:Float) {
		for (side in [1, -1]) {
			var wheel = shadowed(new Mesh(new BoxGeometry(wheelSize, wheelSize, wheelWidth), new MeshLambertMaterial({color: Paint.tyre})), wheelSize / 2, howFarAhead);
			wheel.position.z = side * (CarTuning.width / 2 - wheelWidth / 3);
			whole.add(wheel);
			if (howFarAhead > 0) frontWheels.push(wheel);
		}
	}

	/** A part of the car, lifted to a height and moved along the car, casting a shadow. */
	static function shadowed(part:Mesh, height:Float, along:Float):Mesh {
		part.position.set(along, height, 0);
		part.castShadow = true;
		return part;
	}

	/** The car's number, painted in a disc on a little canvas, laid flat on the roof. */
	static function roofNumber(livery:Livery):Mesh {
		var canvas = Browser.document.createCanvasElement();
		canvas.width = canvas.height = 128;
		var paint = canvas.getContext2d();
		paint.fillStyle = Paint.css(Paint.roofDisc);
		paint.beginPath();
		paint.arc(64, 64, 60, 0, 2 * Math.PI);
		paint.fill();
		paint.fillStyle = Paint.css(Paint.roofNumber);
		paint.font = "800 76px 'Saira Condensed', sans-serif";
		paint.textAlign = "center";
		paint.textBaseline = "middle";
		paint.fillText('${livery.number}', 64, 68);
		return flatOnTheRoof(canvas);
	}

	/** A square of the canvas's picture lying on the roof, readable from the car's left as the camera mostly sees it. */
	static function flatOnTheRoof(canvas:js.html.CanvasElement):Mesh {
		var picture = new MeshBasicMaterial({map: new CanvasTexture(canvas), transparent: true});
		var square = new Mesh(new PlaneGeometry(1.3, 1.3).rotateX(-Math.PI / 2), picture);
		square.position.set(-0.3, roofHeight() + 0.01, 0);
		return square;
	}
}
