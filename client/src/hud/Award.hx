package hud;

import js.html.Element;

/** What a person here takes home from a tournament, by their best place in it. */
enum AwardKind {
	GoldTrophy;
	SilverTrophy;
	BronzeMedal;
	Nothing;
}

/**
 * The award in the top corner of a tournament's final standings (Tom,
 * 4 Nov): a gold trophy for winning it (with fireworks, see `Fireworks`),
 * a smaller silver trophy for second, a bronze medal for third, and
 * nothing for fourth. Drawn as SVG, in the palette's metals (page.html).
 */
class Award {
	final holder:Element;

	public function new(parent:Element) {
		holder = Dom.make("div", "award", null, parent);
		holder.setAttribute("aria-hidden", "true");
	}

	/** The award for finishing in a place (1 = first), or nothing (0 or 4: none shown). */
	public static function forPlace(place:Int):AwardKind {
		return switch place {
			case 1: GoldTrophy;
			case 2: SilverTrophy;
			case 3: BronzeMedal;
			case _: Nothing;
		}
	}

	/** Shows an award (or clears it). */
	public function show(kind:AwardKind) {
		holder.innerHTML = "";
		holder.className = "award";
		switch kind {
			case GoldTrophy: trophy("award-gold");
			case SilverTrophy: trophy("award-silver");
			case BronzeMedal: medal();
			case Nothing:
		}
	}

	/** A cup on a stem and a plinth, with two handles, and a shine down the bowl. */
	function trophy(metal:String) {
		holder.classList.add(metal);
		var drawing = Svg.part("svg", holder, ["viewBox" => "0 0 100 120"]);
		Svg.part("path", drawing, ["class" => "metal-line", "stroke-width" => "7", "d" => "M24 26 C4 26 6 56 30 56 M76 26 C96 26 94 56 70 56"]);
		Svg.part("path", drawing, ["class" => "metal", "d" => "M20 14 H80 V34 C80 58 64 72 50 72 C36 72 20 58 20 34 Z"]);
		Svg.part("path", drawing, ["class" => "shine", "d" => "M30 20 V36 C30 50 36 58 42 62 C36 52 36 42 36 20 Z"]);
		Svg.part("rect", drawing, ["class" => "metal", "x" => "44", "y" => "70", "width" => "12", "height" => "18"]);
		Svg.part("rect", drawing, ["class" => "metal-edge", "x" => "30", "y" => "88", "width" => "40", "height" => "8", "rx" => "2"]);
		Svg.part("rect", drawing, ["class" => "plinth", "x" => "24", "y" => "96", "width" => "52", "height" => "16", "rx" => "2"]);
	}

	/** A round medal on a V of ribbon, a star struck in the middle. */
	function medal() {
		holder.classList.add("award-bronze");
		var drawing = Svg.part("svg", holder, ["viewBox" => "0 0 100 120"]);
		Svg.part("path", drawing, ["class" => "ribbon", "d" => "M28 4 H46 L60 50 H42 Z"]);
		Svg.part("path", drawing, ["class" => "ribbon ribbon-back", "d" => "M72 4 H54 L40 50 H58 Z"]);
		Svg.part("circle", drawing, ["class" => "metal", "cx" => "50", "cy" => "78", "r" => "30"]);
		Svg.part("circle", drawing, ["class" => "metal-line", "stroke-width" => "4", "cx" => "50", "cy" => "78", "r" => "24"]);
		Svg.part("path", drawing, ["class" => "shine", "d" => "M50 62 L54.7 72.5 L66 73.5 L57.5 81 L60 92 L50 86 L40 92 L42.5 81 L34 73.5 L45.3 72.5 Z"]);
	}
}
