package shunt.car;

import shunt.maths.Numbers.degrees;

/**
 * Every number that decides how damage works, in one place (SPEC.md §4b).
 * Starting values, to be tuned by feel.
 */
class DamageTuning {
	// ---- Taking damage ----

	/** A change of speed (m/s) below this does no harm, so ordinary bumping is free. */
	public static inline final harmlessBelow = 3.0;

	/** Damage points for each m/s of change of speed above `harmlessBelow`. */
	public static inline final pointsPerSpeedChange = 4.0;

	/** A zone is wrecked at this many points, and can't get any worse. */
	public static inline final wrecked = 100.0;

	// ---- What damage does ----

	/** At full damage the engine pulls this much less and the top speed is this much lower. */
	public static inline final mostSpeedLost = 0.25;

	/** Front damage above this pulls the steering towards the more damaged side... */
	public static inline final steeringPullsFrom = 40.0;

	/** ...by up to this much, when the front is wrecked: a bent track rod. */
	public static final mostSteeringPull = degrees(4);

	/** Front damage above this takes away some of the steering... */
	public static inline final steeringWeakensFrom = 60.0;

	/** ...up to this share of it, when the front is wrecked. */
	public static inline final mostSteeringLost = 0.3;

	// ---- Oil ----

	/** A car damaged more than this overall is badly damaged, and now and then drops oil. */
	public static inline final leaksOilFrom = 70.0;

	/** The gap between drops, in seconds: random between these, shorter as damage rises. */
	public static inline final shortestOilGap = 4.0;
	public static inline final longestOilGap = 10.0;

	/** An oil patch is a circle reaching this many metres from its middle... */
	public static inline final oilPatchRadius = 2.0;

	/** ...lasting this many seconds, fading away over the last few. */
	public static inline final oilLasts = 20.0;
	public static inline final oilFadesOver = 5.0;

	/** Tyres on oil keep only this share of their grip. */
	public static inline final gripOnOil = 0.3;

	/**
	 * While the rear wheels are on oil the back end steps out: the tail
	 * swings further the way the car is already turning, this fast (radians
	 * per second, per second) on fresh oil. In a straight line nothing
	 * happens; in a bend the car spins.
	 */
	public static inline final oilSwingsTheTail = 15.0;

	/** At most this many patches on the track at once; the oldest goes first. */
	public static inline final mostOilPatches = 6;
}
