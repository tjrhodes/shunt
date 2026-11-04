package view;

import js.Browser;
import js.html.CanvasElement;
import js.html.Element;
import js.html.ImageElement;
import js.html.URL;

/**
 * Pictures of the tracks, for the world behind the ring of cards (Tom,
 * 4 Nov): as the ring turns from one card to the next, the picture of one
 * track crossfades into the picture of the next, in step with the turn.
 * With a card at the front and the ring at rest, the pictures go and the
 * live 3D track shows (it is the same view, so nothing jumps).
 *
 * The pictures are taken here in the browser, not made beforehand: the
 * camera frames each track for the screen it is on, so a picture only
 * matches the live view if it was taken at this very size. The game takes
 * them one a frame while the cards show (see `Game.takeAPicture`), and they
 * are kept as small JPEGs. If the screen changes size they are taken again.
 * Until a track's picture is ready, passing it dips to the night's colour
 * instead.
 */
class Backdrops {
	/** JPEG quality: the pictures only show while moving, so they can be soft. */
	static inline final quality = 0.85;

	/** The ring counts as at rest within this share of a card of one. */
	static inline final atRestWithin = 0.002;

	final stage:Element;
	final behind:ImageElement;
	final inFront:ImageElement;
	final veil:Element;

	/** Each track's picture once asked for (it may still be on its way: see `isReady`). */
	final pictures = new Map<Int, ImageElement>();

	/** The size the pictures were taken at. */
	var takenAt = "";

	/** Two pictures one over the other, and the veil, laid between the 3D track and the panels. */
	public function new(stage:Element, panels:Element) {
		this.stage = stage;
		behind = layer("img", "backdrop", panels);
		inFront = layer("img", "backdrop", panels);
		veil = layer("div", "track-veil", panels);
	}

	static function layer(tag:String, className:String, panels:Element):Dynamic {
		var element = Browser.document.createElement(tag);
		element.className = className;
		element.hidden = true;
		panels.parentElement.insertBefore(element, panels);
		return element;
	}

	/** Whether the ring is at rest: a card right at the front. */
	public static function isAtRest(turn:Float):Bool {
		return Math.abs(turn - Math.round(turn)) < atRestWithin;
	}

	// ---- Taking the pictures ----

	/** The next track without a picture at this screen's size (this one first, the one showing now), or nothing when all have one. */
	public function nextToTake(count:Int, first:Int):Null<Int> {
		forgetIfTheScreenChanged();
		if (!pictures.exists(first)) return first;
		for (track in 0...count) if (!pictures.exists(track)) return track;
		return null;
	}

	/**
	 * Keeps what the 3D view has just drawn as a track's picture. It must be
	 * called straight after drawing (the browser may clear the drawing once
	 * it is on screen). It is copied at the page's own size, which is plenty
	 * for something seen only in passing, then saved as a JPEG.
	 */
	public function keep(track:Int, drawing:CanvasElement) {
		var copy = Browser.document.createCanvasElement();
		copy.width = stage.clientWidth;
		copy.height = stage.clientHeight;
		copy.getContext2d().drawImage(drawing, 0, 0, copy.width, copy.height);
		var picture = Browser.document.createImageElement();
		pictures.set(track, picture);
		copy.toBlob(jpeg -> if (pictures.get(track) == picture) picture.src = URL.createObjectURL(jpeg), "image/jpeg", quality);
	}

	/** Whether a track's picture is taken and ready to show. */
	public function isReady(track:Int):Bool {
		var picture = pictures.get(track);
		return picture != null && picture.complete && picture.naturalWidth > 0;
	}

	/** Pictures taken at another size don't match the view any more: they go, to be taken again. */
	function forgetIfTheScreenChanged() {
		var size = '${stage.clientWidth}x${stage.clientHeight}';
		if (size == takenAt) return;
		for (picture in pictures) if (picture.src != "") URL.revokeObjectURL(picture.src);
		pictures.clear();
		takenAt = size;
	}

	// ---- Showing them ----

	/**
	 * The world behind the ring, for a turn of it. Between two cards: the
	 * nearer card's track, with the other's fading in over it as the ring
	 * gets closer to it. At rest: nothing over the live view, unless the game
	 * is busy taking pictures (`isCovering`), when the front card's picture
	 * hides the view while it shows other tracks.
	 */
	public function show(turn:Float, count:Int, isCovering:Bool) {
		var nearer = Math.round(turn);
		var other = turn >= nearer ? nearer + 1 : nearer - 1;
		var amount = Math.abs(turn - nearer);
		var resting = isAtRest(turn);
		if (resting && !isCovering) return hide();
		if (!isReady(wrapped(nearer, count)) || (!resting && !isReady(wrapped(other, count)))) return dipInstead(amount);
		showPicture(behind, wrapped(nearer, count), 1);
		showPicture(inFront, wrapped(other, count), resting ? 0 : amount);
		veil.hidden = true;
	}

	/** Away: the live view shows. */
	public function hide() {
		behind.hidden = inFront.hidden = veil.hidden = true;
	}

	/** No picture yet: the track behind dips to the night's colour on the way past, deepest halfway (where it changes, unseen). */
	function dipInstead(amount:Float) {
		behind.hidden = inFront.hidden = true;
		veil.hidden = false;
		var share = Math.min(1, 2 * amount);
		veil.style.opacity = '${share * share * (3 - 2 * share)}';
	}

	function showPicture(layer:ImageElement, track:Int, opacity:Float) {
		var source = pictures.get(track).src;
		if (layer.src != source) layer.src = source;
		layer.style.opacity = '$opacity';
		layer.hidden = opacity <= 0;
	}

	static function wrapped(index:Int, count:Int):Int {
		return (index % count + count) % count;
	}
}
