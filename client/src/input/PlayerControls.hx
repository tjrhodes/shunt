package input;

import input.Hands.HandsTogether;
import js.html.Element;
import shunt.car.CarInput;

/**
 * Everything the player can drive with, together as one `CarInput` for the
 * race. Pause and sound are noticed once per press.
 */
class PlayerControls {
	final keyboard = new Keyboard();
	final gamepads = new Gamepads();
	final touch:TouchPads;
	final pausePresses = new PressedOnce();
	final mutePresses = new PressedOnce();

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

	/** True once each time a pause button goes down. */
	public function pauseWasJustPressed():Bool {
		return pausePresses.justNow(allHands().pause);
	}

	/** True once each time a sound button goes down. */
	public function muteWasJustPressed():Bool {
		return mutePresses.justNow(allHands().mute);
	}

	function allHands():Hands {
		return HandsTogether.combine([keyboard.hands(), gamepads.hands(), touch.hands()]);
	}
}
