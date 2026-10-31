package sound;

/** Every number that decides how the game sounds, in one place. Tuned by ear. */
class SoundTuning {
	/** How loud everything is together, 0 to 1. */
	public static inline final overall = 0.7;

	// ---- Engines ----

	/** An engine's note (Hz) at a standstill, how far it climbs through each gear, and how much higher each gear starts. */
	public static inline final idleNote = 45.0;
	public static inline final climbInAGear = 85.0;
	public static inline final gearStep = 10.0;

	/** Gears: the top speed is split into this many, so the note climbs, drops at each change, and climbs again. */
	public static inline final gears = 4;

	/** How bright an engine sounds: the filter opens from this (Hz) off the throttle, by this much more flat out. */
	public static inline final engineDull = 300.0;
	public static inline final engineOpensUpBy = 1800.0;

	/** How loud the player's engine is, and the others'. */
	public static inline final playerEngine = 0.2;
	public static inline final otherEngines = 0.06;

	// ---- Tyres ----

	/** The squeal: the pitch (Hz) of its whine, how narrow (higher is purer), and how loud for the player and the others. */
	public static inline final squealNote = 1400.0;
	public static inline final squealPurity = 7.0;
	public static inline final playerSqueal = 0.25;
	public static inline final otherSqueals = 0.08;

	// ---- Hits ----

	/** A hit this hard (m/s change of speed) or harder is as loud as a hit gets... */
	public static inline final loudestHitFrom = 12.0;

	/** ...which is this loud for the player's car, this loud for the others'. */
	public static inline final playerHit = 0.7;
	public static inline final otherHits = 0.3;

	/** The thump's note (Hz) and how long a hit rings (seconds); a wall scrape is shorter. */
	public static inline final thumpNote = 70.0;
	public static inline final hitRings = 0.35;
	public static inline final scrapeRings = 0.18;

	// ---- Lights ----

	/** The beep for each red light, and the higher, longer one for green (Hz, seconds). */
	public static inline final redBeep = 520.0;
	public static inline final greenBeep = 1040.0;
	public static inline final redBeepLasts = 0.15;
	public static inline final greenBeepLasts = 0.45;
	public static inline final beepLoudness = 0.25;

	/** How quickly a sound follows a change (seconds): short enough to feel instant, long enough not to click. */
	public static inline final followTime = 0.04;
}
