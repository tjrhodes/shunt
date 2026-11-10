package view;

import shunt.maths.Vector;
import shunt.track.Track;

/**
 * A track from above, as lines: every wall, scaled to fit a square
 * `size` across and centred in it, north up. Written as SVG path data
 * ("M x y L x y ..."), which an SVG drawing and a canvas (`Path2D`) both
 * read, so the track cards' maps are drawn one way only.
 */
class TrackMap {
	/** The square the map fits into, in its own units. */
	public static inline final size = 100.0;

	/** The track's walls, as path data in the map square. */
	public static function pathOf(track:Track):String {
		var place = fitIntoTheSquare(track);
		return [for (wall in track.walls) 'M${place(wall.from)}L${place(wall.to)}'].join("");
	}

	/** Where a spot on the track goes in the square ("x y"): the whole track scaled to fill it across its longer side, and centred. */
	static function fitIntoTheSquare(track:Track):Vector -> String {
		var corners = track.wallCorners();
		var west = Lambda.fold(corners, (spot, most) -> Math.min(most, spot.x), Math.POSITIVE_INFINITY);
		var east = Lambda.fold(corners, (spot, most) -> Math.max(most, spot.x), Math.NEGATIVE_INFINITY);
		var south = Lambda.fold(corners, (spot, most) -> Math.min(most, spot.y), Math.POSITIVE_INFINITY);
		var north = Lambda.fold(corners, (spot, most) -> Math.max(most, spot.y), Math.NEGATIVE_INFINITY);
		var fit = size / Math.max(east - west, north - south);
		var left = (size - (east - west) * fit) / 2;
		var top = (size - (north - south) * fit) / 2;
		return spot -> '${Math.round((left + (spot.x - west) * fit) * 10) / 10} ${Math.round((top + (north - spot.y) * fit) * 10) / 10}';
	}
}
