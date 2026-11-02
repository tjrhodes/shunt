package shunt.ai;

/** Every number that decides how the AI drivers drive, in one place (SPEC.md §7). */
class AiTuning {
	// ---- The racing line ----

	/** How much of the tyres' grip the AI dares use in a bend (it leaves a margin). */
	public static inline final shareOfGripInBends = 0.85;

	/** How much of the brakes' full force the AI plans to use, braking for a bend. */
	public static inline final shareOfBrakesPlanned = 0.6;

	// ---- Steering ----

	/** The AI aims at a point this far ahead (metres)... */
	public static inline final shortestLookAhead = 6.0;

	/** ...plus this many seconds' worth of its speed. */
	public static inline final secondsLookAhead = 0.45;

	// ---- Speed ----

	/** Faster than wanted by more than this (m/s), and it brakes; by how much depends on how much faster. */
	public static inline final brakeWhenOverBy = 1.0;
	public static inline final fullBrakeWhenOverBy = 5.0;

	// ---- Character ----

	/**
	 * Each kind of driver's share of the racing line's speeds (which already
	 * keep a margin of grip in hand: over 1 eats into it). They were 0.88 to
	 * 0.98, at random, until 2 Nov: too easy to beat.
	 */
	public static inline final acePace = 1.08;
	public static inline final bruiserPace = 1.04;
	public static inline final steadyPace = 0.97;

	/**
	 * How far from the middle a driver's favourite lane can be, as a share of
	 * the room it has. Hugging the outside wall into a bend puts a car in it.
	 */
	public static inline final widestFavouriteLane = 0.4;

	/** A driver with more aggression than this bumps the car ahead rather than going round it. */
	public static inline final bumpsFromAggression = 0.6;

	// ---- Traffic and oil ----

	/** A car ahead within this many metres along the track, and this far to the side, is in the way. */
	public static inline final trafficAhead = 14.0;
	public static inline final trafficToTheSide = 2.6;

	/** Going round a car or an oil patch, the AI aims this far to its side. */
	public static inline final passingGap = 3.5;

	/** The AI keeps this far in from the walls. */
	public static inline final wallMargin = 1.8;

	/** How far ahead (metres) the AI looks for oil. */
	public static inline final oilLookAhead = 25.0;
}
