package online;

import js.Browser;
import js.lib.Promise;

/**
 * Whether there is a shunt server here to race online on. The page asks
 * for `online.json`, which only the shunt server has (a copy of the game
 * anywhere else, like on claude.ai, stays offline); if it is there, the
 * Colyseus browser client is loaded from it too.
 */
class OnlineServer {
	/** The name a friends' room link carries its room in: ".../?room=abc123". */
	public static inline final roomInTheLink = "room";

	/** Resolves true once online racing is ready, or false if there is none here. */
	public static function lookForOne():Promise<Bool> {
		return Browser.window.fetch("online.json")
			.then(response -> response.ok ? loadTheClient() : Promise.resolve(false))
			.catchError(_ -> false);
	}

	static function loadTheClient():Promise<Bool> {
		return new Promise((ready, _) -> {
			var script = Browser.document.createScriptElement();
			script.src = "colyseus.js";
			script.onload = () -> ready(true);
			script.onerror = () -> ready(false);
			Browser.document.head.appendChild(script);
		});
	}

	/** The room this page's link invites you to, if any. */
	public static function invitation():Null<String> {
		return new js.html.URLSearchParams(Browser.location.search).get(roomInTheLink);
	}

	/** The link to a room, to send to friends. */
	public static function linkTo(roomId:String):String {
		return Browser.location.origin + Browser.location.pathname + '?$roomInTheLink=$roomId';
	}

	/** The server itself (the page came from it). */
	public static function address():String {
		return Browser.location.origin;
	}
}
