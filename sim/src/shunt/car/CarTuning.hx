package shunt.car;

import shunt.maths.Numbers.degrees;

/**
 * Every number that decides how a car feels, in one place (SPEC.md §4).
 * Nothing else in the game writes these numbers again: the physics, the
 * tests and later the renderer all read them from here. They are starting
 * values, to be tuned by feel with someone at the wheel.
 *
 * Units: metres, seconds, kilograms, newtons, radians.
 */
class CarTuning {
	// ---- The body ----

	/** Bumper to bumper, and side to side. */
	public static inline final length = 4.8;
	public static inline final width = 1.9;

	public static inline final mass = 1400.0;

	/** Where the axles sit, measured from the car's centre of mass. */
	public static inline final frontAxleAhead = 1.4;
	public static inline final rearAxleBehind = 1.4;
	public static inline final wheelbase = frontAxleAhead + rearAxleBehind;

	/** How hard it is to start (or stop) the car spinning: that of a solid box this size. */
	public static final turningInertia = mass * (length * length + width * width) / 12;

	/**
	 * How the car's weight is shared between the axles while it sits still:
	 * the axle nearer the middle carries more.
	 */
	public static final frontWeightShare = rearAxleBehind / wheelbase;
	public static final rearWeightShare = frontAxleAhead / wheelbase;

	public static inline final gravity = 9.81;

	// ---- Engine, brakes and air ----

	/** About 150 km/h (with drag, it tops out a little under). */
	public static inline final topSpeed = 42.0;

	/** The engine's pull at a standstill; it fades to nothing at top speed. Gives 0–100 km/h in about 4 s. */
	public static inline final enginePull = 16000.0;

	/** Reverse is slow and weak, as it should be. */
	public static inline final reverseTopSpeed = 8.0;
	public static inline final reversePull = 6000.0;

	/** Full brakes: about 0.9 g. */
	public static inline final brakeForce = 12600.0;

	/** Tyres squash a little as they roll, which always slows the car a bit. */
	public static inline final rollingResistance = 200.0;

	/** Air pushes back harder the faster the car goes: this many newtons per (metre per second) squared. */
	public static inline final airDrag = 0.4;

	/** Slower than this (m/s) counts as stopped, so the brake pedal becomes reverse. */
	public static inline final stoppedBelow = 0.5;

	// ---- Steering and pedals ----

	/** Full lock when slow, much less at speed, so a held key doesn't spin the car at 150 km/h. */
	public static final mostSteeringWhenSlow = degrees(30);
	public static final mostSteeringAtTopSpeed = degrees(8);

	/** How fast the front wheels turn (radians per second): keys are on or off, cars shouldn't be. */
	public static inline final wheelTurnRate = 4.0;

	/** How fast the accelerator goes down or up: from none to full in a quarter of a second. */
	public static inline final throttleRate = 4.0;

	// ---- Tyres ----

	/**
	 * How hard each axle's tyres can push sideways, as a share of the weight
	 * on them (1.15 means 1.15 g). The rear grips a little more than the
	 * front, even at full throttle: when a car is pushed past its grip, the
	 * end that lets go first decides what happens. Front first, and it runs
	 * wide and settles; rear first, and it spins round every time, which is
	 * no fun on a keyboard. Contact and oil still spin cars (SPEC.md §4).
	 */
	public static inline final frontGrip = 1.15;
	public static inline final rearGrip = 1.3;

	/**
	 * The slip angle (between where a tyre points and where it is going) at
	 * which it grips hardest. Below it, grip grows with slip; beyond it the
	 * tyre slides, holding on at its limit.
	 */
	public static final slipAtMostGrip = degrees(7);

	/** Full throttle takes this share of the rear grip away, so the tail can be kicked out (power oversteer). */
	public static inline final rearGripLostToThrottle = 0.1;

	/**
	 * Below this speed (m/s) the tyre sums get jumpy, so the car rolls where
	 * its wheels point instead, blending into the tyre model as it speeds up.
	 */
	public static inline final tyreModelFromSpeed = 2.0;

	/** The most each axle's tyres can push sideways, in newtons. */
	public static final frontGripLimit = frontGrip * mass * gravity * frontWeightShare;
	public static final rearGripLimit = rearGrip * mass * gravity * rearWeightShare;
}
