package view;

import js.Browser;
import shunt.car.Car;
import shunt.car.CarTuning;
import three.Three;
import view.Paint.Livery;

/**
 * One car in 3D: our own little 1960s rally saloon, simplified to chunky
 * low-poly shapes and built to the simulation's own size (`CarTuning`): a
 * body in its livery with a short sloping bonnet and a small boot, a tall
 * glasshouse under a contrasting roof, wheels pushed out to the corners,
 * chrome bumpers, round lamps and a pair of rally spotlights, and its
 * number on the roof and on both doors.
 *
 * Everything is drawn inside the box the race uses for the car, wheels
 * and bumpers and lamps included: anything poking out would look like
 * cars sinking into each other when they are only touching.
 *
 * The front wheels turn as the car's wheels do, and hits dent the body
 * (drawn only: the simulation's damage zones are what count, SPEC.md §10).
 */
class CarView {
	// ---- Sizes, in metres ----
	static inline final rideHeight = 0.18;
	static inline final bodyHeight = 0.62;
	static inline final cabinLength = 2.0;
	static inline final cabinHeight = 0.58;
	static inline final cabinBack = -0.2;
	static inline final roofThickness = 0.09;
	static inline final wheelRadius = 0.32;
	static inline final wheelWidth = 0.26;
	static inline final lampRadius = 0.11;

	/** The bumpers take up this much of each end of the car's box, and the wheels this much of each side, so the body is that much smaller. */
	static inline final bumperDepth = 0.1;
	static inline final wheelsStickOutBy = 0.08;

	/** The cabin narrows towards the roof: its top is this share of its bottom's length and width. */
	static inline final cabinTopShare = 0.82;

	/** The bonnet and boot slope down to the bumpers by this much, so the car isn't a plain brick. */
	static inline final endsDropBy = 0.12;

	/** The body is built of this many pieces along, up and across, so a dent has corners to push in. */
	static inline final piecesAlong = 10;
	static inline final piecesUp = 2;
	static inline final piecesAcross = 4;

	/** A dent reaches this far (metres) round the point of a hit... */
	static inline final dentReach = 0.9;

	/** ...and goes in this far for each m/s the hit changed the car's speed, up to the most. */
	static inline final dentPerSpeedChange = 0.022;
	static inline final deepestDent = 0.26;

	static inline final halfLength = CarTuning.length / 2;
	static inline final halfWidth = CarTuning.width / 2;
	static inline final bodyHalfLength = halfLength - bumperDepth;
	static inline final bodyHalfWidth = halfWidth - wheelsStickOutBy;

	public final whole = new Group();
	final frontWheels:Array<Mesh> = [];
	final body:Mesh;
	final bodyUndented:Array<Float>;

	public function new(livery:Livery) {
		body = shadowed(new Mesh(bodyShape(), new MeshLambertMaterial({color: livery.colour})), rideHeight + bodyHeight / 2, 0);
		bodyUndented = [for (number in body.geometry.attributes.position.array) number];
		whole.add(body);
		addCabinAndRoof(livery);
		for (axle in [CarTuning.frontAxleAhead, -CarTuning.rearAxleBehind]) addWheels(axle);
		for (end in [1, -1]) addBumperAndLamps(end);
		addSpotlights();
		for (side in [1, -1]) whole.add(doorNumber(livery, side));
	}

	/** Moves the car to where the simulation has it (between two ticks, for smoothness). */
	public function show(car:Car, heading:Float, position:shunt.maths.Vector) {
		Placing.put(whole, position, 0, heading);
		for (wheel in frontWheels) wheel.rotation.y = -car.wheelAngle;
	}

	// ---- The body ----

	/** The body: a box the car's size, its top sloping down over the bonnet and the boot. */
	static function bodyShape():BufferGeometry {
		var shape = new BoxGeometry(bodyHalfLength * 2, bodyHeight, bodyHalfWidth * 2, piecesAlong, piecesUp, piecesAcross);
		var corners = shape.attributes.position;
		for (corner in 0...corners.count) slopeTheEnds(corners.array, corner);
		shape.computeVertexNormals();
		return shape;
	}

	/** A corner on top of the body, beyond the cabin, drops a little the nearer it is to the bumper. */
	static function slopeTheEnds(numbers:js.lib.Float32Array, corner:Int) {
		var x = numbers[corner * 3];
		var isOnTop = numbers[corner * 3 + 1] > 0;
		var beyondTheCabin = x > cabinBack + cabinLength / 2 ? x - (cabinBack + cabinLength / 2) : (x < cabinBack - cabinLength / 2 ? (cabinBack - cabinLength / 2) - x : 0);
		var shareToTheEnd = beyondTheCabin / (bodyHalfLength - cabinLength / 2 + Math.abs(cabinBack));
		if (isOnTop) numbers[corner * 3 + 1] -= endsDropBy * Math.min(1, shareToTheEnd);
	}

	/** The glasshouse, narrowing as it rises, and the roof on top, a little wider, in the roof colour. */
	function addCabinAndRoof(livery:Livery) {
		var cabin = new BoxGeometry(cabinLength, cabinHeight, bodyHalfWidth * 2 * 0.92);
		narrowTowardsTheTop(cabin);
		whole.add(shadowed(new Mesh(cabin, new MeshLambertMaterial({color: Paint.glass})), rideHeight + bodyHeight + cabinHeight / 2, cabinBack));
		var roof = new BoxGeometry(cabinLength * cabinTopShare + 0.1, roofThickness, bodyHalfWidth * 2 * 0.92 * cabinTopShare + 0.1);
		whole.add(shadowed(new Mesh(roof, new MeshLambertMaterial({color: Paint.roof})), roofHeight() - roofThickness / 2, cabinBack));
		whole.add(roofNumber(livery));
	}

	/** Pulls the top corners of a box in towards its middle. */
	static function narrowTowardsTheTop(shape:BufferGeometry) {
		var corners = shape.attributes.position;
		for (corner in 0...corners.count) if (corners.array[corner * 3 + 1] > 0) {
			corners.array[corner * 3] *= cabinTopShare;
			corners.array[corner * 3 + 2] *= cabinTopShare;
		}
		shape.computeVertexNormals();
	}

	static function roofHeight():Float {
		return rideHeight + bodyHeight + cabinHeight + roofThickness;
	}

	// ---- Wheels, bumpers and lamps ----

	/** A pair of round wheels on an axle, out at the car's sides (just inside its box). The front pair are remembered, to steer. */
	function addWheels(howFarAhead:Float) {
		for (side in [1, -1]) {
			var wheel = shadowed(new Mesh(new CylinderGeometry(wheelRadius, wheelRadius, wheelWidth, 12).rotateX(Math.PI / 2), new MeshLambertMaterial({color: Paint.tyre})), wheelRadius, howFarAhead);
			wheel.position.z = side * (halfWidth - wheelWidth / 2);
			whole.add(wheel);
			if (howFarAhead > 0) frontWheels.push(wheel);
		}
	}

	/** A chrome bumper across one end, with two round lamps above it: headlights at the front (1), tail lights at the back (-1). */
	function addBumperAndLamps(end:Int) {
		var bumper = shadowed(new Mesh(new BoxGeometry(bumperDepth, 0.12, CarTuning.width - 0.04), new MeshLambertMaterial({color: Paint.chrome})), rideHeight + 0.12, end * (halfLength - bumperDepth / 2));
		whole.add(bumper);
		for (side in [1, -1]) whole.add(roundLamp(end > 0 ? lampRadius : lampRadius * 0.7, end > 0 ? Paint.headlight : Paint.tailLight, end * (bodyHalfLength + 0.01), rideHeight + bodyHeight * 0.62, side * bodyHalfWidth * 0.62));
	}

	/** Two rally spotlights on the front bumper, close together. */
	function addSpotlights() {
		for (side in [1, -1]) whole.add(roundLamp(lampRadius * 0.85, Paint.headlight, halfLength - 0.03, rideHeight + 0.3, side * halfWidth * 0.24));
	}

	/** A round lamp facing out of the car's end, glowing (unlit by anything). */
	static function roundLamp(radius:Float, colour:Int, along:Float, height:Float, across:Float):Mesh {
		var lamp = new Mesh(new CylinderGeometry(radius, radius, 0.06, 10).rotateZ(Math.PI / 2), new MeshBasicMaterial({color: colour}));
		lamp.position.set(along, height, across);
		return lamp;
	}

	/** A part of the car, lifted to a height and moved along the car, casting a shadow. */
	static function shadowed(part:Mesh, height:Float, along:Float):Mesh {
		part.position.set(along, height, 0);
		part.castShadow = true;
		return part;
	}

	// ---- Numbers ----

	/** The number, lying flat on the roof, readable from the car's left as the camera mostly sees it. */
	static function roofNumber(livery:Livery):Mesh {
		var square = new Mesh(new PlaneGeometry(1.0, 1.0).rotateX(-Math.PI / 2), numberPicture(livery));
		square.position.set(cabinBack, roofHeight() + 0.01, 0);
		return square;
	}

	/** The number on a door, standing on one side of the car (1: left, -1: right), facing out. */
	static function doorNumber(livery:Livery, side:Int):Mesh {
		var panel = new Mesh(new PlaneGeometry(0.5, 0.5), numberPicture(livery));
		panel.position.set(cabinBack + 0.15, rideHeight + bodyHeight * 0.5, -side * (bodyHalfWidth + 0.01));
		panel.rotation.y = side > 0 ? Math.PI : 0;
		return panel;
	}

	/** The car's number, in black on a white disc, painted on a little canvas. */
	static function numberPicture(livery:Livery):Material {
		var canvas = Browser.document.createCanvasElement();
		canvas.width = canvas.height = 128;
		var paint = canvas.getContext2d();
		paint.fillStyle = Paint.css(Paint.roofDisc);
		paint.beginPath();
		paint.arc(64, 64, 60, 0, 2 * Math.PI);
		paint.fill();
		paint.fillStyle = Paint.css(Paint.roofNumber);
		paint.font = Lettering.heavy(76);
		paint.textAlign = "center";
		paint.textBaseline = "middle";
		paint.fillText('${livery.number}', 64, 68);
		return new MeshBasicMaterial({map: new CanvasTexture(canvas), transparent: true});
	}

	// ---- Dents ----

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
}
