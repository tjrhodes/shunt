package input;

import input.Hands.HandsTogether;
import js.html.Element;
import js.html.PointerEvent;
import hud.Words;
import js.Browser;

/**
 * Driving by touch (SPEC.md §1): hold the left half of the screen to steer
 * left and the right half to steer right (both, and it goes straight),
 * building the longer a finger is held. The
 * car accelerates by itself once touch is in use; a pad in the corner brakes,
 * and a button at the top pauses. Both appear at the first touch.
 */
class TouchPads {
	final fingersOnTheScreen = new Map<Int, Float>();
	final stage:Element;
	final buttons:Array<Element>;
	final steeringRamp = new SteeringRamp();
	var isInUse = false;
	var isBraking = false;
	var isPausing = false;

	public function new(stage:Element, brakePad:Element, pauseButton:Element) {
		this.stage = stage;
		buttons = [brakePad, pauseButton];
		brakePad.textContent = Words.brake;
		pauseButton.textContent = Words.pause;
		Browser.window.addEventListener("pointerdown", (event:PointerEvent) -> if (event.pointerType == "touch") startUsingTouch());
		stage.addEventListener("pointerdown", (event:PointerEvent) -> fingerDown(event));
		stage.addEventListener("pointermove", (event:PointerEvent) -> if (fingersOnTheScreen.exists(event.pointerId)) fingerDown(event));
		for (ending in ["pointerup", "pointercancel"]) stage.addEventListener(ending, (event:PointerEvent) -> fingersOnTheScreen.remove(event.pointerId));
		whileHeld(brakePad, isHeld -> isBraking = isHeld);
		whileHeld(pauseButton, isHeld -> isPausing = isHeld);
	}

	public function hands():Hands {
		if (!isInUse) return HandsTogether.nothingPressed;
		return {
			throttle: isBraking ? 0 : 1,
			brake: isBraking ? 1 : 0,
			steer: steeringRamp.steering(Lambda.fold([for (side in fingersOnTheScreen) side], (side, total) -> total + side, 0.0)),
			recover: false,
			pause: isPausing
		};
	}

	/** From the first touch anywhere (even on the start button), the car goes by itself and the touch buttons show. */
	function startUsingTouch() {
		if (isInUse) return;
		isInUse = true;
		for (button in buttons) button.hidden = false;
	}

	/** Tells `changed` when a button goes down (true) and when it is let go (false). */
	static function whileHeld(button:Element, changed:Bool -> Void) {
		button.addEventListener("pointerdown", () -> changed(true));
		for (ending in ["pointerup", "pointercancel", "pointerleave"]) button.addEventListener(ending, () -> changed(false));
	}

	/** A finger down (or sliding) on the stage: which half of the screen it is on is which way it steers. */
	function fingerDown(event:PointerEvent) {
		if (event.pointerType != "touch") return;
		startUsingTouch();
		var bounds = stage.getBoundingClientRect();
		fingersOnTheScreen.set(event.pointerId, event.clientX < bounds.left + bounds.width / 2 ? -1 : 1);
	}
}
