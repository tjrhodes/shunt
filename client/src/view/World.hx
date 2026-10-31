package view;

import js.Browser;
import js.html.Element;
import shunt.track.Track;
import three.Three;

/**
 * The 3D scene: the renderer drawing into the page, the lights, the
 * isometric camera, and the track. Cars and oil are added by the game.
 */
class World {
	/** How far a hard hit shakes the view, at most, in metres; it dies away by this share each frame. */
	static inline final mostShake = 0.6;
	static inline final shakeLeftEachFrame = 0.85;

	public final scene = new Scene();
	final renderer = new WebGLRenderer({antialias: true});
	final view:IsometricCamera;
	final stage:Element;
	var shake = 0.0;

	public function new(track:Track, stage:Element) {
		this.stage = stage;
		view = new IsometricCamera([for (index in 0...track.samples.length) for (side in [1, -1]) track.edgeAt(index, side)]);
		scene.background = new Color(Paint.sky);
		scene.add(TrackView.build(track));
		lightUp(track);
		renderer.shadowMap.enabled = true;
		stage.appendChild(renderer.domElement);
		fitTheScreen();
		Browser.window.addEventListener("resize", fitTheScreen);
	}

	/** Draws a frame, with any shake from a hit nudging the camera. */
	public function draw() {
		var nudge = shake * Math.sin(Browser.window.performance.now() / 23);
		view.camera.position.x += nudge;
		renderer.render(scene, view.camera);
		view.camera.position.x -= nudge;
		shake *= shakeLeftEachFrame;
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

	/** Soft light from the sky and the infield, and one floodlight casting shadows over the whole track. */
	function lightUp(track:Track) {
		scene.add(new HemisphereLight(Paint.skyGlow, Paint.groundGlow, 0.75));
		var flood = new DirectionalLight(Paint.floodlight, 0.85);
		flood.position.set(-60, 120, 40);
		flood.castShadow = true;
		flood.shadow.mapSize.width = flood.shadow.mapSize.height = 2048;
		var reach = track.length / 3;
		flood.shadow.camera.left = flood.shadow.camera.bottom = -reach;
		flood.shadow.camera.right = flood.shadow.camera.top = reach;
		flood.shadow.camera.far = 400;
		scene.add(flood);
	}
}
