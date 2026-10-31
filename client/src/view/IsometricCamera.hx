package view;

import shunt.maths.Vector;
import three.Three;

/** The track as seen across the screen: how far it reaches each way, from its middle. */
typedef ScreenSpan = {
	final left:Float;
	final right:Float;
	final bottom:Float;
	final top:Float;
}

/**
 * A fixed camera looking down at the isometric angle (35.26° down), framing
 * the whole track on any screen (SPEC.md §1, §10), so every player always
 * sees every car. It tries looking from every 15° round the track and picks
 * the way that fills the screen best: on a wide screen the oval lies across
 * it, on a tall phone it stands up.
 */
class IsometricCamera {
	static final lookingDown = Math.atan(1 / Math.sqrt(2));
	static final waysRound = [for (step in 0...24) step * 15 * Math.PI / 180];

	/** A little room round the track, as a share of its size. */
	static inline final margin = 0.06;

	/** How far back the camera stands: far enough for nothing to be behind it. */
	static inline final distance = 500.0;

	public final camera = new OrthographicCamera(-1, 1, 1, -1, 1, 2000);
	final trackEdge:Array<Vector>;
	final middle:Vector;

	public function new(trackEdge:Array<Vector>) {
		this.trackEdge = trackEdge;
		middle = middleOf(trackEdge);
	}

	/** Frames the track for a screen this many pixels wide and high. */
	public function frame(width:Float, height:Float) {
		var bestWay = waysRound[0];
		for (way in waysRound) if (pixelsPerMetre(way, width, height) > pixelsPerMetre(bestWay, width, height)) bestWay = way;
		standLookingFrom(bestWay);
		fitTheView(spanAcrossTheScreen(bestWay), width / height);
	}

	/** Puts the camera up and back from the track's middle, at the isometric angle, looking at it. */
	function standLookingFrom(wayRound:Float) {
		var back = directionTowardsTheCamera(wayRound);
		camera.position.set(Placing.sceneX(middle) + back.x * distance, back.y * distance, Placing.sceneZ(middle) + back.z * distance);
		camera.lookAt(Placing.sceneX(middle), 0, Placing.sceneZ(middle));
	}

	/** Sets how much of the world the camera shows: the track's span, widened to the screen's shape, plus a margin. */
	function fitTheView(span:ScreenSpan, screenShape:Float) {
		var width = (span.right - span.left) * (1 + margin);
		var height = (span.top - span.bottom) * (1 + margin);
		if (width / height < screenShape) width = height * screenShape; else height = width / screenShape;
		var middleAcross = (span.left + span.right) / 2;
		var middleUp = (span.bottom + span.top) / 2;
		camera.left = middleAcross - width / 2;
		camera.right = middleAcross + width / 2;
		camera.bottom = middleUp - height / 2;
		camera.top = middleUp + height / 2;
		camera.updateProjectionMatrix();
	}

	/** How big the track would look from one way round: bigger is better. */
	function pixelsPerMetre(wayRound:Float, width:Float, height:Float):Float {
		var span = spanAcrossTheScreen(wayRound);
		return Math.min(width / (span.right - span.left), height / (span.top - span.bottom));
	}

	/** How far the track's edge reaches left, right, down and up the screen from its middle. */
	function spanAcrossTheScreen(wayRound:Float):ScreenSpan {
		var across = screenAcross(wayRound);
		var up = screenUp(wayRound);
		var acrossDistances = [for (spot in trackEdge) metresAlong(spot, across)];
		var upDistances = [for (spot in trackEdge) metresAlong(spot, up)];
		return {left: lowest(acrossDistances), right: highest(acrossDistances), bottom: lowest(upDistances), top: highest(upDistances)};
	}

	/** How far a spot on the ground is from the track's middle along a screen direction. */
	function metresAlong(spot:Vector, screenDirection:Vector3):Float {
		return (Placing.sceneX(spot) - Placing.sceneX(middle)) * screenDirection.x + (Placing.sceneZ(spot) - Placing.sceneZ(middle)) * screenDirection.z;
	}

	/** The direction from what the camera looks at back to the camera (one long). */
	static function directionTowardsTheCamera(wayRound:Float):Vector3 {
		var flat = Math.cos(lookingDown);
		return new Vector3(flat * Math.cos(wayRound), Math.sin(lookingDown), flat * Math.sin(wayRound));
	}

	/** The world direction that runs left to right across the screen: level, square to the way the camera looks. */
	static function screenAcross(wayRound:Float):Vector3 {
		return new Vector3(Math.sin(wayRound), 0, -Math.cos(wayRound));
	}

	/**
	 * The world direction that runs up the screen, as far as the ground goes:
	 * away from the camera, shortened because the ground is seen at a slant.
	 */
	static function screenUp(wayRound:Float):Vector3 {
		var slant = Math.sin(lookingDown);
		return new Vector3(-Math.cos(wayRound) * slant, 0, -Math.sin(wayRound) * slant);
	}

	static function middleOf(spots:Array<Vector>):Vector {
		var xs = spots.map(spot -> spot.x);
		var ys = spots.map(spot -> spot.y);
		return new Vector((lowest(xs) + highest(xs)) / 2, (lowest(ys) + highest(ys)) / 2);
	}

	static function lowest(values:Array<Float>):Float {
		return Lambda.fold(values, Math.min, Math.POSITIVE_INFINITY);
	}

	static function highest(values:Array<Float>):Float {
		return Lambda.fold(values, Math.max, Math.NEGATIVE_INFINITY);
	}
}
