package view;

import js.Browser;
import js.html.CanvasElement;
import js.html.Element;
import shunt.track.Track;
import three.Three;

/**
 * The track cards as a ring in 3D (Tom, 2 Nov): the cards stand in a
 * circle with their backs out; the chosen one slides out of the ring
 * towards you and turns round to show its face. Choosing another turns the
 * ring, and the old card swings back into its place as the new one comes
 * out past it. Everything eases towards where it should be, so a quick
 * run through the cards flows rather than jumps.
 *
 * It has its own small 3D view, drawn into the panel; the track behind is
 * the game's world, as before.
 */
class CardRing {
	// ---- Sizes (metres of the ring's own little world) ----
	static inline final cardWide = 1.0;
	static inline final cardTall = 1.4;
	static inline final ringRadius = 2.7;

	/** How far towards the camera the chosen card comes, how much higher, and how much bigger. */
	static inline final comesOutBy = 1.5;
	static inline final risesBy = 0.12;
	static inline final growsBy = 0.2;

	/** How quickly things ease to where they should be: this share of the way per... */
	static inline final easing = 7.0;

	/** The canvas the faces are painted on: this many pixels per metre of card. */
	static inline final pixelsPerMetre = 420;

	public final element:CanvasElement;
	final renderer = new WebGLRenderer({antialias: true, alpha: true});
	final scene = new Scene();
	final camera = new PerspectiveCamera(30, 1, 0.1, 40);
	final cards:Array<Group>;
	final outness:Array<Float>;
	final raycaster = new Raycaster();
	final picked:Int -> Void;
	var turn = 0.0;
	var turnWanted = 0.0;

	public function new(tracks:Array<Track>, picked:Int -> Void) {
		this.picked = picked;
		element = renderer.domElement;
		element.className = "card-ring";
		cards = [for (track in tracks) cardFor(track)];
		outness = [for (_ in cards) 0.0];
		for (card in cards) scene.add(card);
		camera.position.set(0, 0.75, 6.0);
		camera.lookAt(0, 0.1, -0.6);
		element.addEventListener("click", whereClicked);
	}

	/** A card chosen: the ring turns the short way round to bring it out. */
	public function choose(index:Int) {
		var count = cards.length;
		var nearest = Math.round(turnWanted / count) * count + index;
		var options = [nearest - count, nearest, nearest + count];
		turnWanted = Lambda.fold(options, (option, best) -> Math.abs(option - turnWanted) < Math.abs(best - turnWanted) ? option : best, options[1]);
		if (prefersLessMotion()) turn = turnWanted;
	}

	/** Moves everything on by some seconds of easing, and draws. */
	public function animate(seconds:Float) {
		var share = prefersLessMotion() ? 1 : 1 - Math.exp(-easing * seconds);
		turn += (turnWanted - turn) * share;
		var chosen = wrapped(Math.round(turnWanted));
		for (index in 0...cards.length) {
			outness[index] += ((index == chosen ? 1 : 0) - outness[index]) * share;
			place(cards[index], index);
		}
		fitTheView();
		renderer.render(scene, camera);
	}

	/**
	 * A card where it should be now. In the ring it stands at its place round
	 * the circle, back out; as it comes out it moves towards the camera,
	 * rises, grows, and turns half round to face it.
	 */
	function place(card:Group, index:Int) {
		var angle = 2 * Math.PI * placeInTheRing(index) / cards.length;
		var out = smoothly(outness[index]);
		var inRingX = ringRadius * Math.sin(angle);
		var inRingZ = ringRadius * Math.cos(angle) - ringRadius;
		card.position.set(inRingX * (1 - out), risesBy * out, inRingZ * (1 - out) + comesOutBy * out);
		card.rotation.y = (angle + Math.PI) * (1 - out);
		card.scale.set(1 + growsBy * out, 1 + growsBy * out, 1);
	}

	/** How many places round from the front of the ring a card is (between half the ring back and half forward). */
	function placeInTheRing(index:Int):Float {
		var count = cards.length;
		var away = (index - turn) % count;
		if (away > count / 2) away -= count;
		if (away < -count / 2) away += count;
		return away;
	}

	function wrapped(index:Int):Int {
		return ((index % cards.length) + cards.length) % cards.length;
	}

	/** An ease in and out (0 to 1, gentle at both ends). */
	static function smoothly(share:Float):Float {
		return share * share * (3 - 2 * share);
	}

	// ---- The cards themselves ----

	/** One track's card: its face (the map, name, family, laps) on the front, the game's pattern on the back. */
	static function cardFor(track:Track):Group {
		var card = new Group();
		var front = new Mesh(new PlaneGeometry(cardWide, cardTall), new MeshBasicMaterial({map: new CanvasTexture(CardFaces.front(track, canvasOfACard()))}));
		var back = new Mesh(new PlaneGeometry(cardWide, cardTall), new MeshBasicMaterial({map: new CanvasTexture(CardFaces.back(canvasOfACard()))}));
		back.rotation.y = Math.PI;
		card.add(front);
		card.add(back);
		return card;
	}

	static function canvasOfACard():CanvasElement {
		var canvas = Browser.document.createCanvasElement();
		canvas.width = Math.round(cardWide * pixelsPerMetre);
		canvas.height = Math.round(cardTall * pixelsPerMetre);
		return canvas;
	}

	// ---- The view, and clicks ----

	/** The drawing is as big as the space it has in the panel (it changes with the window). */
	function fitTheView() {
		var wide = element.clientWidth;
		var tall = element.clientHeight;
		if (wide == 0 || tall == 0) return;
		var pixels = Math.min(2, Browser.window.devicePixelRatio);
		if (element.width == Math.round(wide * pixels) && element.height == Math.round(tall * pixels)) return;
		renderer.setPixelRatio(pixels);
		renderer.setSize(wide, tall, false);
		camera.aspect = wide / tall;
		camera.updateProjectionMatrix();
	}

	/** A click on a card picks it (the one already out, or one in the ring). */
	function whereClicked(event:js.html.MouseEvent) {
		var bounds = element.getBoundingClientRect();
		var x = (event.clientX - bounds.left) / bounds.width * 2 - 1;
		var y = -((event.clientY - bounds.top) / bounds.height * 2 - 1);
		raycaster.setFromCamera(new Vector2(x, y), camera);
		var hits = raycaster.intersectObjects(cast cards, true);
		if (hits.length > 0) picked(cards.indexOf(cast hits[0].object.parent));
	}

	static function prefersLessMotion():Bool {
		return Browser.window.matchMedia("(prefers-reduced-motion: reduce)").matches;
	}
}
