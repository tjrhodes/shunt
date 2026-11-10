package view;

/**
 * The game's typefaces, as the portfolio site uses them (Fira Sans, and Fira
 * Sans Condensed for anything shouted). The stylesheet names the same ones;
 * this is for words painted into the 3D world: car numbers and billboards.
 */
class Lettering {
	/** The heavy condensed face, at a size in pixels, as a canvas font. */
	public static function heavy(pixels:Int):String {
		return '900 ${pixels}px "Fira Sans Condensed", "Arial Narrow", sans-serif';
	}
}
