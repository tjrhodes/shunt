package shunt.race;

/** Every number that decides how a race runs, in one place (SPEC.md §1 and §6). */
class RaceTuning {
	public static inline final defaultLaps = 5;

	// ---- The start ----

	/** Three red lights come on a second apart; a second after the third, they go green. */
	public static inline final redLights = 3;
	public static inline final secondsBetweenLights = 1.0;

	/** The grid: each car on its own row, this far back from the start line, alternating left and right. */
	public static inline final firstRowBehindTheLine = 8.0;
	public static inline final rowGap = 7.0;

	// ---- Laps ----

	/**
	 * The lap is split into this many equal parts by checkpoints (the start
	 * line is the first). A lap only counts once every checkpoint has been
	 * passed in order, so cutting across the infield gets you nothing.
	 */
	public static inline final checkpoints = 4;

	/**
	 * How far (in metres along the track) a car can have moved since it was
	 * last seen: where to look for it on the track, and how soon after a
	 * checkpoint it must be spotted.
	 */
	public static inline final trackSearchReach = 30.0;

	/** Once the leader finishes, the others have this long to finish too. */
	public static inline final secondsToFinishAfterTheLeader = 10.0;

	// ---- Getting cars going again ----

	/** A car slower than this (m/s) counts as stuck. */
	public static inline final stuckBelowSpeed = 1.0;

	/**
	 * A car facing the wrong way: how its nose lines up with the race
	 * direction, from 1 (spot on) to -1 (straight back). Below this is wrong.
	 */
	public static inline final wrongWayBelow = -0.5;

	/** Stuck or facing the wrong way for this long, and a car is put back on the track. */
	public static inline final secondsInTroubleBeforeHelp = 3.0;

	/** A car put back starts at walking pace, and passes through other cars for a moment. */
	public static inline final speedWhenPutBack = 2.0;
	public static inline final secondsAsAGhost = 1.5;

	/** Finished cars coast round with a dab of brake. */
	public static inline final brakeWhenFinished = 0.2;
}
