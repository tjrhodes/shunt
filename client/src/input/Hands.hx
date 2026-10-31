package input;

/**
 * What one way of driving (keyboard, a gamepad, touch) has pressed right
 * now: how hard on each pedal, which way to steer, and whether it asks to be
 * put back on the track, to pause, or to turn the sound off or on.
 */
typedef Hands = {
	final throttle:Float;
	final brake:Float;
	final steer:Float;
	final recover:Bool;
	final pause:Bool;
	final mute:Bool;
}

class HandsTogether {
	public static final nothingPressed:Hands = {
		throttle: 0,
		brake: 0,
		steer: 0,
		recover: false,
		pause: false,
		mute: false
	};

	/**
	 * Several hands on the controls at once, as one: whichever pedal is
	 * pressed hardest anywhere, the steering added up (the car keeps it in
	 * range), and any button pressed anywhere.
	 */
	public static function combine(all:Array<Hands>):Hands {
		return {
			throttle: Lambda.fold(all, (hands, most) -> Math.max(most, hands.throttle), 0.0),
			brake: Lambda.fold(all, (hands, most) -> Math.max(most, hands.brake), 0.0),
			steer: Lambda.fold(all, (hands, total) -> total + hands.steer, 0.0),
			recover: Lambda.exists(all, hands -> hands.recover),
			pause: Lambda.exists(all, hands -> hands.pause),
			mute: Lambda.exists(all, hands -> hands.mute)
		};
	}
}
