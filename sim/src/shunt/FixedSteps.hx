package shunt;

/**
 * Keeps the race in step with real time (SPEC.md §3). The screen draws
 * whenever it can (60, 90, 144 times a second...), but the race only ever
 * moves in whole ticks of exactly 1/120 s. Each frame this says how many
 * ticks are due, and how far into the next tick real time has got, so cars
 * can be drawn between where they were and where they are.
 */
class FixedSteps {
	/** At most this many ticks in one frame: after a stall (a hidden tab), the race doesn't race to catch up. */
	final mostTicksPerFrame:Int;

	/** Adding up times leaves tiny rounding errors: without this, a tick that is due now can wait a frame and two come together. */
	static inline final roundingSlack = 1e-6;

	var lastSeconds = -1.0;
	var timeNotYetTicked = 0.0;

	/**
	 * On this computer 8 a frame is plenty. Online, time lost puts a browser
	 * behind the server for the rest of the race (Tom, 5 Nov: on a slow
	 * frame the cars jumped), so it catches up further (`OnlineTuning`).
	 */
	public function new(mostTicksPerFrame = 8) {
		this.mostTicksPerFrame = mostTicksPerFrame;
	}

	/** How many ticks to run now, given the frame's time in milliseconds. */
	public function ticksDue(nowMilliseconds:Float):Int {
		var now = nowMilliseconds / 1000;
		if (lastSeconds >= 0) timeNotYetTicked += now - lastSeconds;
		lastSeconds = now;
		var due = Math.floor(timeNotYetTicked / Tick.seconds + roundingSlack);
		timeNotYetTicked -= due * Tick.seconds;
		if (due <= mostTicksPerFrame) return due;
		timeNotYetTicked = 0;
		return mostTicksPerFrame;
	}

	/** How far real time has got into the next tick, from 0 to 1. */
	public function shareIntoTheNextTick():Float {
		return timeNotYetTicked / Tick.seconds;
	}

	/** Forgets the time that passed while stopped (paused, or before the start). */
	public function startAfresh() {
		lastSeconds = -1;
		timeNotYetTicked = 0;
	}
}
