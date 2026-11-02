package hud;

import js.Browser;
import js.html.Element;
import shunt.maths.Vector;
import shunt.track.Track;

/**
 * The first stage of the start (Tom, 2 Nov: "a carousel of tracks on
 * cards"): one card per track in a row that slides, the chosen one in the
 * middle. A card shows the track's map, drawn from its very own walls, its
 * name, its family, and its laps and length. The 3D track behind changes to
 * the chosen one, so a card is a preview too.
 */
class TrackCards {
	/** A map is drawn this many units across; the walls are this thick on it. */
	static inline final mapSize = 100.0;
	static inline final wallThickness = 1.6;

	final cards:Array<Element>;

	public function new(parent:Element, tracks:Array<Track>, choose:Int -> Void) {
		var row = Dom.make("div", "track-cards", null, parent);
		row.setAttribute("role", "listbox");
		row.setAttribute("aria-label", Words.chooseATrack);
		cards = [for (index in 0...tracks.length) card(tracks[index], row, () -> choose(index))];
	}

	/** Marks the chosen card, and slides the row so it sits in the middle. */
	public function mark(chosen:Int) {
		for (index in 0...cards.length) cards[index].setAttribute("aria-selected", '${index == chosen}');
		slideToTheMiddle(cards[chosen]);
	}

	/**
	 * Slides the row (only the row: the browser's own scrollIntoView would
	 * slide the panels too, and on a phone push the title off the side) so
	 * a card sits in its middle.
	 */
	function slideToTheMiddle(card:Element) {
		var row:Dynamic = card.parentElement;
		var left = card.offsetLeft - (row.clientWidth - card.offsetWidth) / 2;
		row.scrollTo(js.Syntax.code("{left: {0}, behavior: {1}}", left, reducedMotion() ? "auto" : "smooth"));
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

	/** The track from above, as lines: every wall, fitted into the map square and centred in it, north up. */
	static function mapOf(track:Track):Element {
		var place = fitIntoTheMap(track);
		var lines = [for (wall in track.walls) 'M${place(wall.from)}L${place(wall.to)}'];
		var drawing = Svg.part("svg", null, ["viewBox" => '-4 -4 ${mapSize + 8} ${mapSize + 8}', "class" => "track-card-map", "aria-hidden" => "true"]);
		Svg.part("path", drawing, ["d" => lines.join(""), "stroke-width" => '$wallThickness']);
		return drawing;
	}

	/** Where a spot on the track goes on the map ("x y"): the whole track scaled to fill the square across its longer side, and centred. */
	static function fitIntoTheMap(track:Track):Vector -> String {
		var corners = track.wallCorners();
		var west = Lambda.fold(corners, (spot, most) -> Math.min(most, spot.x), Math.POSITIVE_INFINITY);
		var east = Lambda.fold(corners, (spot, most) -> Math.max(most, spot.x), Math.NEGATIVE_INFINITY);
		var south = Lambda.fold(corners, (spot, most) -> Math.min(most, spot.y), Math.POSITIVE_INFINITY);
		var north = Lambda.fold(corners, (spot, most) -> Math.max(most, spot.y), Math.NEGATIVE_INFINITY);
		var fit = mapSize / Math.max(east - west, north - south);
		var left = (mapSize - (east - west) * fit) / 2;
		var top = (mapSize - (north - south) * fit) / 2;
		return spot -> '${Math.round((left + (spot.x - west) * fit) * 10) / 10} ${Math.round((top + (north - spot.y) * fit) * 10) / 10}';
	}

	static function reducedMotion():Bool {
		return Browser.window.matchMedia("(prefers-reduced-motion: reduce)").matches;
	}
}
