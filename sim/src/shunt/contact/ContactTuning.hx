package shunt.contact;

/** Every number that decides how hits feel, in one place (SPEC.md §4). Starting values, to be tuned by feel. */
class ContactTuning {
	/**
	 * How bouncy a hit is: 0 and the two stay together, 1 and they spring
	 * apart as fast as they met. Cars are a bit bouncy; walls soak up more.
	 */
	public static inline final carBounce = 0.3;
	public static inline final wallBounce = 0.2;

	/** How much rubbing slows a scrape along the other car or wall (0 is ice, 1 is very grippy). */
	public static inline final carScrape = 0.4;
	public static inline final wallScrape = 0.5;

	/**
	 * Walls are this many metres from their middle line to their face (half
	 * their thickness). More than a car can move in one tick, so a car can
	 * never get through one.
	 */
	public static inline final wallHalfThickness = 0.5;

	/** Each tick, overlapping things are pushed apart by this share of the overlap: steady, without jitter. */
	public static inline final pushApartShare = 0.8;
}
