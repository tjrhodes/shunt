package input;

/**
 * One thing a person can drive with. Two people can share the keyboard (one
 * on each half), and every gamepad is its own; touch is for one person
 * alone, so it can't be claimed for a seat.
 */
enum Controller {
	KeyboardLeft;
	KeyboardRight;
	Pad(slot:Int);
	Touch;
}

class Controllers {
	/** The same controller always has the same name: handy for remembering things about it. */
	public static function key(controller:Controller):String {
		return switch controller {
			case KeyboardLeft: "keys-left";
			case KeyboardRight: "keys-right";
			case Pad(slot): 'pad-$slot';
			case Touch: "touch";
		}
	}

	/** Whether two controllers are the same one. */
	public static function same(one:Controller, other:Controller):Bool {
		return key(one) == key(other);
	}

	/** Whether a controller can claim a seat of its own (touch can't: it is the whole screen). */
	public static function canClaimASeat(controller:Controller):Bool {
		return controller != Touch;
	}
}
