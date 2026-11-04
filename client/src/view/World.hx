package view;

import js.Browser;
import js.html.Element;
import shunt.maths.Vector;
import shunt.track.Track;

using Lambda;
import three.Three;

/**
 * The 3D scene: the renderer drawing into the page, the lights, the
 * isometric camera, and the track being raced on. Cars and oil are added by
 * the game.
 */
class World {
	/** How far a hard hit shakes the view, at most, in metres; it dies away by this share each frame. */
	static inline final mostShake = 0.6;
	static inline final shakeLeftEachFrame = 0.85;

	/** The floodlight stands this far off the track's middle (on the ground), and this high. */
	static final floodlightComesFrom = new Vector(-60, -40);
	static inline final floodlightHeight = 120.0;

	public final scene = new Scene();
	final renderer = new WebGLRenderer({antialias: true});
	final floodlight = new DirectionalLight(Paint.floodlight, 0.85);
	final stage:Element;
	var view:IsometricCamera;
	var trackShown:Null<Group> = null;
	var shake = 0.0;

	public function new(stage:Element) {
		this.stage = stage;
		scene.background = new Color(Paint.sky);
		lightUp();
		renderer.shadowMap.enabled = true;
		stage.appendChild(renderer.domElement);
		Browser.window.addEventListener("resize", fitTheScreen);
	}

	/** Puts a track in the scene (in place of any other), aims the floodlight at it, and frames it. */
	public function showTrack(track:Track) {
		if (trackShown != null) letGo(trackShown);
		trackShown = TrackView.build(track);
		scene.add(trackShown);
		view = new IsometricCamera(track.wallCorners());
		shadowsOver(track);
		fitTheScreen();
	}

	/**
	 * A track taken out of the scene, and let go on the graphics card too:
	 * its shapes, paints and painted pictures (each track is built afresh, and
	 * taking the tracks' pictures builds every one, so they would pile up).
	 */
	function letGo(track:Group) {
		scene.remove(track);
		track.traverse(part -> {
			var piece:Dynamic = part;
			if (piece.geometry != null) piece.geometry.dispose();
			if (piece.material != null && piece.material.map != null) piece.material.map.dispose();
			if (piece.material != null) piece.material.dispose();
		});
	}

	/** Draws a frame, with any shake from a hit nudging the camera. */
	public function draw() {
		var nudge = shake * Math.sin(Browser.window.performance.now() / 23);
		view.camera.position.x += nudge;
		renderer.render(scene, view.camera);
		view.camera.position.x -= nudge;
		shake *= shakeLeftEachFrame;
	}

	/** What the view is drawn on: a picture can be taken of it straight after drawing. */
	public function drawing():js.html.CanvasElement {
		return renderer.domElement;
	}

	/** Shakes the view by a share of the most, unless the viewer prefers less motion. */
	public function shakeFor(shareOfMost:Float) {
		if (Browser.window.matchMedia("(prefers-reduced-motion: reduce)").matches) return;
		shake = Math.max(shake, mostShake * Math.min(1, shareOfMost));
	}

	/** Sizes the drawing to the page and frames the track for its shape. */
	function fitTheScreen() {
		var width = stage.clientWidth;
		var height = stage.clientHeight;
		renderer.setPixelRatio(Math.min(2, Browser.window.devicePixelRatio));
		renderer.setSize(width, height);
		view.frame(width, height);
	}

	/** Soft light from the sky and the infield, and one floodlight that casts shadows. */
	function lightUp() {
		scene.add(new HemisphereLight(Paint.skyGlow, Paint.groundGlow, 0.75));
		floodlight.castShadow = true;
		scene.add(floodlight.target);
		floodlight.shadow.mapSize.width = floodlight.shadow.mapSize.height = 2048;
		floodlight.shadow.camera.far = 400;
		scene.add(floodlight);
	}

	/**
	 * Aims the floodlight at the middle of a track, from up and to one side,
	 * with its shadows covering the whole track and no more (so they stay sharp).
	 */
	function shadowsOver(track:Track) {
		var corners = track.wallCorners();
		var middle = corners.fold((corner:Vector, total:Vector) -> total + corner, Vector.nothing()) * (1 / corners.length);
		var reach = corners.fold((corner, furthest) -> Math.max(furthest, corner.distanceTo(middle)), 0.0) + 10;
		Placing.put(floodlight.target, middle, 0, 0);
		Placing.put(floodlight, middle + floodlightComesFrom, floodlightHeight, 0);
		var shadows = floodlight.shadow.camera;
		shadows.left = shadows.bottom = -reach;
		shadows.right = shadows.top = reach;
		shadows.updateProjectionMatrix();
	}
}
