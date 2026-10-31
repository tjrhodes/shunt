package hud;

import js.Browser;
import js.html.Element;
import shunt.car.Car;
import shunt.car.DamageTuning;

/**
 * The player's car from above, small, in the HUD (SPEC.md §4b): its front,
 * back and sides each shaded by how battered they are, from barely there
 * to red. Read straight from the simulation's damage zones.
 */
class DamageOutline {
	static inline final svgWords = "http://www.w3.org/2000/svg";

	/** The drawing's size, and how thick each zone's bar is (the car points up the drawing). */
	static inline final wide = 26;
	static inline final long = 46;
	static inline final bar = 5;

	final front:Element;
	final rear:Element;
	final left:Element;
	final right:Element;

	public function new(plate:Element) {
		var drawing = svgPart("svg", plate, ["viewBox" => '0 0 $wide $long', "class" => "damage-outline", "aria-hidden" => "true"]);
		svgPart("rect", drawing, ["x" => '$bar', "y" => '$bar', "width" => '${wide - 2 * bar}', "height" => '${long - 2 * bar}', "rx" => "3", "class" => "damage-body"]);
		front = zone(drawing, bar, 0, wide - 2 * bar, bar);
		rear = zone(drawing, bar, long - bar, wide - 2 * bar, bar);
		left = zone(drawing, 0, bar, bar, long - 2 * bar);
		right = zone(drawing, wide - bar, bar, bar, long - 2 * bar);
	}

	/** Shades each zone by its damage: the stylesheet turns `--harm` (0 to 1) into a colour. */
	public function show(car:Car) {
		var zones = car.damage;
		for (pair in [{part: front, harm: zones.front}, {part: rear, harm: zones.rear}, {part: left, harm: zones.left}, {part: right, harm: zones.right}]) {
			var share = '${Math.round(100 * pair.harm / DamageTuning.wrecked) / 100}';
			if (pair.part.style.getPropertyValue("--harm") != share) pair.part.style.setProperty("--harm", share);
		}
	}

	function zone(drawing:Element, x:Int, y:Int, width:Int, height:Int):Element {
		return svgPart("rect", drawing, ["x" => '$x', "y" => '$y', "width" => '$width', "height" => '$height', "rx" => "1.5", "class" => "damage-zone"]);
	}

	/** A part of an SVG drawing, with its attributes, put inside its parent. */
	static function svgPart(tag:String, parent:Element, attributes:Map<String, String>):Element {
		var part = Browser.document.createElementNS(svgWords, tag);
		for (name => value in attributes) part.setAttribute(name, value);
		parent.appendChild(part);
		return part;
	}
}
