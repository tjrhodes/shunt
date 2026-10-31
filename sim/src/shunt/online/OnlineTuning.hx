package shunt.online;

/** Every number that decides how racing online works, in one place (SPEC.md §9). */
@:expose("OnlineTuning") @:keep
class OnlineTuning {
	/** Cars in an online race: people take seats, AI drivers fill the rest. */
	public static inline final seats = 4;

	/** The most people one browser can bring (everyone on its keyboard and gamepads). */
	public static inline final mostPeoplePerBrowser = 4;

	/** The most browsers in a room: people beyond the seats watch until a seat is free. */
	public static final mostBrowsers = 8;

	/** The server sends where everything is every this many ticks (120 / 4 = 30 times a second). */
	public static inline final ticksBetweenSnapshots = 4;

	/**
	 * A browser's inputs wait in a queue at the server, one used per tick.
	 * If more than this many pile up (the network bunched them), the oldest
	 * are dropped so that browser isn't driving further and further behind.
	 */
	public static inline final mostInputsWaiting = 12;

	/** Other people's cars are drawn this far in the past, between two snapshots, so they move smoothly. */
	public static inline final othersShownSecondsBehind = 0.1;

	/** When the server corrects your car, the difference is eased in over this long rather than jumping. */
	public static inline final correctionEasedOverSeconds = 0.15;

	/** A correction bigger than this (metres) is a real disagreement (a crash seen differently): snapped, not eased. */
	public static inline final snapCorrectionsOver = 4.0;

	/** In a quick match, once two people are in, the race starts by itself after this long. */
	public static inline final quickMatchStartsAfterSeconds = 15.0;
}
