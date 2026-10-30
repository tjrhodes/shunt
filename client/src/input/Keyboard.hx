package input;

import js.Browser;
import js.html.KeyboardEvent;

/** Driving with the keyboard: arrows or WASD, R to be put back, Esc or P to pause. */
class Keyboard {
	static final throttleKeys = ["ArrowUp", "KeyW"];
	static final brakeKeys = ["ArrowDown", "KeyS"];
	static final leftKeys = ["ArrowLeft", "KeyA"];
	static final rightKeys = ["ArrowRight", "KeyD"];
	static final recoverKeys = ["KeyR"];
	static final pauseKeys = ["Escape", "KeyP"];

	final keysDown = new Map<String, Bool>();

	public function new() {
		Browser.window.addEventListener("keydown", (event:KeyboardEvent) -> pressed(event, true));
		Browser.window.addEventListener("keyup", (event:KeyboardEvent) -> pressed(event, false));
		Browser.window.addEventListener("blur", () -> keysDown.clear());
	}

	/** Keys are on or off, so pedals and steering are all or nothing; the car smooths them. */
	public function hands():Hands {
		return {
			throttle: anyDown(throttleKeys) ? 1 : 0,
			brake: anyDown(brakeKeys) ? 1 : 0,
			steer: (anyDown(rightKeys) ? 1 : 0) - (anyDown(leftKeys) ? 1 : 0),
			recover: anyDown(recoverKeys),
			pause: anyDown(pauseKeys)
		};
	}

	/** Remembers a key going down or up. Driving keys don't scroll the page. */
	function pressed(event:KeyboardEvent, isDown:Bool) {
		keysDown.set(event.code, isDown);
		var drivingKeys = throttleKeys.concat(brakeKeys).concat(leftKeys).concat(rightKeys);
		if (drivingKeys.contains(event.code)) event.preventDefault();
	}

	function anyDown(keys:Array<String>):Bool {
		return Lambda.exists(keys, key -> keysDown.get(key) == true);
	}
}
