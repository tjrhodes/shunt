package input;

/**
 * Turns a button that is held into a press that happens once: holding
 * pause shouldn't pause and unpause over and over.
 */
class PressedOnce {
	var wasDown = false;

	public function new() {}

	/** True only on the first moment a button is seen down after being up. */
	public function justNow(isDown:Bool):Bool {
		var isNew = isDown && !wasDown;
		wasDown = isDown;
		return isNew;
	}
}
