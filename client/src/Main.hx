import js.Browser;
import js.html.Element;
import shunt.track.Track;
import view.Paint;

/**
 * Starts the game once the page is ready: waits for the fonts (the car
 * numbers are painted in them), loads the track, and hands both to `Game`.
 */
class Main {
	static inline final trackFile = "tracks/oval.json";

	static function main() {
		givePagePlayerColour();
		Browser.document.fonts.ready.then(_ -> Browser.window.fetch(trackFile))
			.then(response -> response.text())
			.then(text -> new Game(Track.fromJson(text), pageParts()));
	}

	/** The page's stylesheet takes the player's colour from the same place the 3D car does. */
	static function givePagePlayerColour() {
		Browser.document.documentElement.style.setProperty("--player", Paint.css(Paint.liveries[0].colour));
	}

	static function pageParts():Game.PageParts {
		return {
			stage: part("stage"),
			hud: part("hud"),
			panels: part("panels"),
			brakePad: part("brake-pad"),
			pauseButton: part("pause-button")
		};
	}

	static function part(id:String):Element {
		return Browser.document.getElementById(id);
	}
}
