package shunt;

/**
 * The simulation's heartbeat. The race always moves on in steps of exactly
 * this length, however fast or slow the screen draws, so the same inputs
 * always give the same race (SPEC.md §3). 120 a second is fast enough that a
 * car at top speed moves less than half a metre per step, so nothing can
 * jump through a wall.
 */
class Tick {
	public static inline final perSecond = 120;
	public static inline final seconds = 1 / perSecond;

	/** How many ticks make up a number of seconds (to the nearest tick). */
	public static inline function ticksIn(seconds:Float):Int {
		return Math.round(seconds * perSecond);
	}
}
