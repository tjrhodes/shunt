package hud;

import js.Browser;
import js.html.Element;

/** Making parts of SVG drawings (the car's damage outline, the track maps on the cards). */
class Svg {
	static inline final svgWords = "http://www.w3.org/2000/svg";

	/** A part of an SVG drawing, with its attributes, put inside its parent if it has one. */
	public static function part(tag:String, parent:Null<Element>, attributes:Map<String, String>):Element {
		var part = Browser.document.createElementNS(svgWords, tag);
		for (name => value in attributes) part.setAttribute(name, value);
		if (parent != null) parent.appendChild(part);
		return part;
	}
}
