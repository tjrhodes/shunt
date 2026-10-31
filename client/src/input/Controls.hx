package input;

import input.Controller;
import input.Hands.HandsTogether;
import js.html.Element;
import shunt.car.CarInput;

using input.Controller.Controllers;

/**
 * Every controller there is (both keyboard halves, each gamepad, touch),
 * and what each has pressed. A seat's car input comes from the controllers
 * driving it; pause, sound and yes come from anyone. Presses that should
 * happen once (pause, sound, yes, joining and leaving a seat) are noticed
 * once per press.
 */
class Controls {
	/** A pedal pressed further than this counts as pressed, for joining and leaving a seat. */
	static inline final pressedFurtherThan = 0.5;

	final keyboard = new Keyboard();
	final gamepads = new Gamepads();
	final touch:TouchPads;
	final pausePresses = new PressedOnce();
	final mutePresses = new PressedOnce();
	final confirmPresses = new PressedOnce();
	final throttlePresses = new Map<String, PressedOnce>();
	final brakePresses = new Map<String, PressedOnce>();

	public function new(stage:Element, brakePad:Element, pauseButton:Element) {
		touch = new TouchPads(stage, brakePad, pauseButton);
	}

	/** Every controller there is now (gamepads come and go). */
	public function every():Array<Controller> {
		return [KeyboardLeft, KeyboardRight, Touch].concat([for (slot in gamepads.slots()) Pad(slot)]);
	}

	/** The car input from some controllers together (none: nothing pressed). */
	public function carInputFrom(controllers:Array<Controller>):CarInput {
		var together = HandsTogether.combine(controllers.map(handsOf));
		return {
			throttle: together.throttle,
			brake: together.brake,
			steer: together.steer,
			recover: together.recover
		};
	}

	/** True once each time anyone's pause button goes down. */
	public function pauseWasJustPressed():Bool {
		return pausePresses.justNow(everyonesHands().pause);
	}

	/** True once each time anyone's sound button goes down. */
	public function muteWasJustPressed():Bool {
		return mutePresses.justNow(everyonesHands().mute);
	}

	/** True once each time anyone's yes button (a gamepad's A) goes down. */
	public function confirmWasJustPressed():Bool {
		return confirmPresses.justNow(everyonesHands().confirm);
	}

	/** The controllers whose throttle has just gone down: asking to join. */
	public function throttleJustPressedOn():Array<Controller> {
		return justPressedOn(throttlePresses, hands -> hands.throttle);
	}

	/** The controllers whose brake has just gone down: asking to leave. */
	public function brakeJustPressedOn():Array<Controller> {
		return justPressedOn(brakePresses, hands -> hands.brake);
	}

	/** Every controller whose pedal (as `pedal` reads it) has just been pressed down; each is asked every time, so none misses its moment. */
	function justPressedOn(presses:Map<String, PressedOnce>, pedal:Hands -> Float):Array<Controller> {
		var pressedNow:Array<Controller> = [];
		for (controller in every()) {
			if (!presses.exists(controller.key())) presses.set(controller.key(), new PressedOnce());
			if (presses.get(controller.key()).justNow(pedal(handsOf(controller)) > pressedFurtherThan)) pressedNow.push(controller);
		}
		return pressedNow;
	}

	function handsOf(controller:Controller):Hands {
		return switch controller {
			case KeyboardLeft: keyboard.hands(true);
			case KeyboardRight: keyboard.hands(false);
			case Pad(slot): gamepads.hands(slot);
			case Touch: touch.hands();
		}
	}

	function everyonesHands():Hands {
		return HandsTogether.combine(every().map(handsOf));
	}
}
