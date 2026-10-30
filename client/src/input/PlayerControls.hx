package input;

import input.Hands.HandsTogether;
import js.html.Element;
import shunt.car.CarInput;

/**
 * Everything the player can drive with, together as one `CarInput` for the
 * race. Pause is noticed once per press.
 */
class PlayerControls {
	final keyboard = new Keyboard();
	final gamepads = new Gamepads();
	final touch:TouchPads;
	var wasPausePressed = false;

	public function new(stage:Element, brakePad:Element, pauseButton:Element) {
		touch = new TouchPads(stage, brakePad, pauseButton);
	}

	/** The player's car input this tick. */
	public function carInput():CarInput {
		var together = allHands();
		return {
			throttle: together.throttle,
			brake: together.brake,
			steer: together.steer,
			recover: together.recover
		};
	}

	/** True once each time a pause button goes down (holding it doesn't pause and unpause over and over). */
	public function pauseWasJustPressed():Bool {
		var isPressed = allHands().pause;
		var justNow = isPressed && !wasPausePressed;
		wasPausePressed = isPressed;
		return justNow;
	}

	function allHands():Hands {
		return HandsTogether.combine([keyboard.hands(), gamepads.hands(), touch.hands()]);
	}
}
