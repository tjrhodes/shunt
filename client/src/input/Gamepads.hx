package input;

import js.Browser;
import input.Hands.HandsTogether;
import js.html.Gamepad;
import js.html.GamepadMappingType;

/**
 * Driving with a gamepad (the browser's "standard" button layout): right
 * trigger to go, left trigger to brake, left stick to steer, Y to be put
 * back, Start to pause. Every connected pad drives the player's car for now;
 * in phase 2 each pad gets its own seat.
 */
class Gamepads {
	static inline final rightTrigger = 7;
	static inline final leftTrigger = 6;
	static inline final buttonY = 3;
	static inline final startButton = 9;

	/** Stick movement smaller than this is the stick's own wobble, not steering. */
	static inline final stickWobble = 0.12;

	public function new() {}

	/** Every connected pad's hands, together. */
	public function hands():Hands {
		return HandsTogether.combine(connectedPads().map(handsOn));
	}

	static function handsOn(pad:Gamepad):Hands {
		return {
			throttle: pad.buttons[rightTrigger].value,
			brake: pad.buttons[leftTrigger].value,
			steer: steeringOf(pad),
			recover: pad.buttons[buttonY].pressed,
			pause: pad.buttons[startButton].pressed
		};
	}

	/** The left stick's side-to-side, with its wobble taken out. */
	static function steeringOf(pad:Gamepad):Float {
		var stick = pad.axes[0];
		return Math.abs(stick) < stickWobble ? 0 : stick;
	}

	/** Pads with the standard layout that are plugged in now. */
	static function connectedPads():Array<Gamepad> {
		var navigator:Dynamic = Browser.navigator;
		if (navigator.getGamepads == null) return [];
		var slots:Array<Gamepad> = navigator.getGamepads();
		return [for (pad in slots) if (pad != null && pad.mapping == STANDARD && pad.buttons.length > startButton) pad];
	}
}
