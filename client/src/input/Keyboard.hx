package input;

import js.Browser;
import js.html.KeyboardEvent;

/** One half of the keyboard: its own keys for driving, and its own steering build-up. */
typedef KeyboardHalf = {
	final throttle:Array<String>;
	final brake:Array<String>;
	final left:Array<String>;
	final right:Array<String>;
	final recover:Array<String>;
	final steeringRamp:SteeringRamp;
}

/**
 * Driving with the keyboard. It has two halves, so two people can share it:
 * WASD with R to be put back on the left, the arrows with / to be put back
 * on the right. Esc or P pauses and M turns the sound off or on, from
 * either half. (Many keyboards can't tell more than a few keys at once, so
 * two people can sometimes block each other's keys.)
 */
class Keyboard {
	static final leftHalf:KeyboardHalf = {throttle: ["KeyW"], brake: ["KeyS"], left: ["KeyA"], right: ["KeyD"], recover: ["KeyR"], steeringRamp: new SteeringRamp()};
	static final rightHalf:KeyboardHalf = {throttle: ["ArrowUp"], brake: ["ArrowDown"], left: ["ArrowLeft"], right: ["ArrowRight"], recover: ["Slash"], steeringRamp: new SteeringRamp()};
	static final pauseKeys = ["Escape", "KeyP"];
	static final muteKeys = ["KeyM"];

	final keysDown = new Map<String, Bool>();

	public function new() {
		Browser.window.addEventListener("keydown", (event:KeyboardEvent) -> pressed(event, true));
		Browser.window.addEventListener("keyup", (event:KeyboardEvent) -> pressed(event, false));
		Browser.window.addEventListener("blur", () -> keysDown.clear());
	}

	/** What one half has pressed. Keys are on or off, so pedals are all or nothing (the car smooths them); steering builds while a key is held. */
	public function hands(isLeftHalf:Bool):Hands {
		var half = isLeftHalf ? leftHalf : rightHalf;
		return {
			throttle: anyDown(half.throttle) ? 1 : 0,
			brake: anyDown(half.brake) ? 1 : 0,
			steer: half.steeringRamp.steering((anyDown(half.right) ? 1 : 0) - (anyDown(half.left) ? 1 : 0), secondsNow()),
			recover: anyDown(half.recover),
			pause: anyDown(pauseKeys),
			mute: anyDown(muteKeys),
			confirm: false
		};
	}

	/** Remembers a key going down or up. Driving keys don't scroll the page. */
	function pressed(event:KeyboardEvent, isDown:Bool) {
		keysDown.set(event.code, isDown);
		if (isADrivingKey(event.code)) event.preventDefault();
	}

	static function isADrivingKey(code:String):Bool {
		return Lambda.exists([leftHalf, rightHalf], half -> half.throttle.concat(half.brake).concat(half.left).concat(half.right).concat(half.recover).contains(code));
	}

	static function secondsNow():Float {
		return Browser.window.performance.now() / 1000;
	}

	function anyDown(keys:Array<String>):Bool {
		return Lambda.exists(keys, key -> keysDown.get(key) == true);
	}
}
