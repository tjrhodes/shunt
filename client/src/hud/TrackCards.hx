package hud;

import js.Browser;
import js.html.Element;
import view.CardRing;
import view.TrackMap;
import shunt.track.Track;

/**
 * The first stage of the start (Tom, 2 Nov: "a carousel of tracks on
 * cards"): one card per track. A card shows the track's map, drawn from its
 * very own walls, its name, its family, and its laps and length. The 3D
 * track behind changes to the chosen one, so a card is a preview too.
 */
class TrackCards {
	/** The walls are this thick on a card's map (which is `TrackMap.size` across). */
	static inline final wallThickness = 1.6;

	final cards:Array<Element>;
	final ring:CardRing;

	/**
	 * The cards are shown as a ring in 3D (`CardRing`); the same cards as
	 * plain buttons stay underneath, out of sight, for screen readers and
	 * anything that can't draw 3D.
	 */
	public function new(parent:Element, tracks:Array<Track>, choose:Int -> Void) {
		ring = new CardRing(tracks, choose);
		parent.appendChild(ring.element);
		var row = Dom.make("div", "track-cards visually-hidden", null, parent);
		row.setAttribute("role", "listbox");
		row.setAttribute("aria-label", Words.chooseATrack);
		cards = [for (index in 0...tracks.length) card(tracks[index], row, () -> choose(index))];
	}

	/** Marks the chosen card, and turns the ring to bring it out. */
	public function mark(chosen:Int) {
		for (index in 0...cards.length) cards[index].setAttribute("aria-selected", '${index == chosen}');
		ring.choose(chosen);
	}

	/** Moves the ring on by some seconds, and draws it. */
	public function animate(seconds:Float) {
		ring.animate(seconds);
	}


	/** One track's card: its map, then its name, family, and laps and length. */
	static function card(track:Track, row:Element, pick:() -> Void):Element {
		var card = Dom.button("", "track-card", row, pick);
		card.setAttribute("role", "option");
		card.appendChild(mapOf(track));
		Dom.make("span", "track-card-name", track.name, card);
		Dom.make("span", "track-card-family", Words.families.get(track.family) ?? "", card);
		Dom.make("span", "track-card-laps", Words.lapsAndLength(track.laps, track.length), card);
		return card;
	}

	/** The track's map, as a small SVG drawing (`TrackMap` works out the lines). */
	static function mapOf(track:Track):Element {
		var room = TrackMap.size;
		var drawing = Svg.part("svg", null, ["viewBox" => '-4 -4 ${room + 8} ${room + 8}', "class" => "track-card-map", "aria-hidden" => "true"]);
		Svg.part("path", drawing, ["d" => TrackMap.pathOf(track), "stroke-width" => '$wallThickness']);
		return drawing;
	}

	static function reducedMotion():Bool {
		return Browser.window.matchMedia("(prefers-reduced-motion: reduce)").matches;
	}
}
