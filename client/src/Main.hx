import haxe.Json;
import js.Browser;
import js.lib.Promise;
import js.html.Element;
import shunt.track.Track;
import view.Paint;

/**
 * Starts the game once the page is ready: waits for the fonts (the car
 * numbers are painted in them), loads every track in the list the checks
 * read too (`tracks/index.json`), and hands them to `Game`.
 */
class Main {
	static inline final trackFolder = "tracks/";

	static function main() {
		givePagePlayerColour();
		Browser.document.fonts.ready.then(_ -> textOf("index.json"))
			.then(list -> Promise.all([for (file in (Json.parse(list) : Array<String>)) textOf(file)]))
			.then(files -> new Game([for (file in files) Track.fromJson(file)], pageParts()));
	}

	/** The text of a file in the tracks folder. */
	static function textOf(file:String):Promise<String> {
		return Browser.window.fetch(trackFolder + file).then(response -> response.text());
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
