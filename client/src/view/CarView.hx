package view;

import js.Browser;
import shunt.car.Car;
import shunt.car.CarTuning;
import three.Three;
import view.Paint.Livery;

/**
 * One car in 3D: a low-poly stock car built from boxes to the simulation's
 * own size, in its livery, with its number on the roof. The front wheels
 * turn as the car's wheels do.
 */
class CarView {
	static inline final bodyHeight = 0.75;
	static inline final rideHeight = 0.2;
	static inline final cabinLength = 2.2;
	static inline final cabinHeight = 0.55;
	static inline final wheelSize = 0.7;
	static inline final wheelWidth = 0.32;

	public final whole = new Group();
	final frontWheels:Array<Mesh> = [];

	public function new(livery:Livery) {
		whole.add(shadowed(new Mesh(new BoxGeometry(CarTuning.length, bodyHeight, CarTuning.width), new MeshLambertMaterial({color: livery.colour})), rideHeight + bodyHeight / 2, 0));
		whole.add(shadowed(new Mesh(new BoxGeometry(cabinLength, cabinHeight, CarTuning.width * 0.84), new MeshLambertMaterial({color: Paint.glass})), roofHeight() - cabinHeight / 2, -0.3));
		whole.add(roofNumber(livery));
		for (axle in [CarTuning.frontAxleAhead, -CarTuning.rearAxleBehind]) addWheels(axle);
	}

	/** Moves the car to where the simulation has it (between two ticks, for smoothness). */
	public function show(car:Car, heading:Float, position:shunt.maths.Vector) {
		Placing.put(whole, position, 0, heading);
		for (wheel in frontWheels) wheel.rotation.y = -car.wheelAngle;
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
