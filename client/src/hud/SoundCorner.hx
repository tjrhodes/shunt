package hud;

import js.html.Element;

/**
 * A small sound button in the top corner of the start screens (Tom, 4 Nov:
 * "we need some sound controls"): a speaker, with sound waves when sound is
 * on and a cross when it's off. The same choice as the M key and the pause
 * panel's button, remembered between visits.
 */
class SoundCorner {
	final button:Element;

	public function new(page:Element, toggle:() -> Void) {
		button = Dom.button("", "sound-corner", page, toggle);
		var drawing = Svg.part("svg", button, ["viewBox" => "0 0 24 24", "aria-hidden" => "true"]);
		Svg.part("path", drawing, ["class" => "speaker", "d" => "M3 9h4l5-4v14l-5-4H3z"]);
		Svg.part("path", drawing, ["class" => "waves", "d" => "M15.5 8.5a5 5 0 0 1 0 7M18.5 5.5a9 9 0 0 1 0 13"]);
		Svg.part("path", drawing, ["class" => "cross", "d" => "M16 9l6 6M22 9l-6 6"]);
	}

	/** Shows whether sound is on, for eyes and for screen readers. */
	public function showSoundAs(isOn:Bool) {
		button.classList.toggle("is-off", !isOn);
		button.setAttribute("aria-pressed", '$isOn');
		button.setAttribute("aria-label", isOn ? Words.soundIsOn : Words.soundIsOff);
		button.title = isOn ? Words.soundIsOn : Words.soundIsOff;
	}
}
