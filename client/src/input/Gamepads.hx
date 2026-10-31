package input;

import js.Browser;
import js.html.Gamepad;
import js.html.GamepadMappingType;

/**
 * Driving with gamepads (the browser's "standard" button layout): right
 * trigger to go, left trigger to brake, left stick to steer, Y to be put
 * back, Start to pause, Select for sound off or on, A to say yes to a
 * panel. Each pad is its own controller, known by the slot the browser
 * gives it.
 */
class Gamepads {
	static inline final buttonA = 0;
	static inline final buttonY = 3;
	static inline final leftTrigger = 6;
	static inline final rightTrigger = 7;
	static inline final selectButton = 8;
	static inline final startButton = 9;

	/** Stick movement smaller than this is the stick's own wobble, not steering. */
	static inline final stickWobble = 0.12;

	public function new() {}

	/** The slots of the pads plugged in now. */
	public function slots():Array<Int> {
		return [for (pad in connectedPads()) pad.index];
	}

	/** What the pad in a slot has pressed (nothing, if it has gone). */
	public function hands(slot:Int):Hands {
		for (pad in connectedPads()) if (pad.index == slot) return handsOn(pad);
		return Hands.HandsTogether.nothingPressed;
	}

	static function handsOn(pad:Gamepad):Hands {
		return {
			throttle: pad.buttons[rightTrigger].value,
			brake: pad.buttons[leftTrigger].value,
			steer: steeringOf(pad),
			recover: pad.buttons[buttonY].pressed,
			pause: pad.buttons[startButton].pressed,
			mute: pad.buttons[selectButton].pressed,
			confirm: pad.buttons[buttonA].pressed
		};
	}

	/** The left stick's side-to-side, with its wobble taken out. */
	static function steeringOf(pad:Gamepad):Float {
		var stick = pad.axes[0];
		return Math.abs(stick) < stickWobble ? 0 : stick;
	}

	/** Pads with the standard layout that are plugged in now (none, if the browser has no gamepads or isn't allowed them here). */
	static function connectedPads():Array<Gamepad> {
		var navigator:Dynamic = Browser.navigator;
		if (navigator.getGamepads == null) return [];
		var slots:Array<Gamepad> = try navigator.getGamepads() catch (_) [];
		return [for (pad in slots) if (pad != null && pad.mapping == STANDARD && pad.buttons.length > startButton) pad];
	}
}
