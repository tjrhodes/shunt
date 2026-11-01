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

	/** About 165 km/h (with drag, it tops out a little under). */
	public static inline final topSpeed = 46.0;

	/** The engine's pull at a standstill; it fades to nothing at top speed. Gives 0–100 km/h in about 4 s. */
	public static inline final enginePull = 15500.0;

	/**
	 * Lifting off the accelerator slows the car too: the engine holds it
	 * back (engine braking), with this force when the pedal is fully up, and
	 * a quarter of it at half throttle (it goes with the square of the lift).
	 */
	public static inline final engineBraking = 10000.0;

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
	public static final mostSteeringAtTopSpeed = degrees(9);

	/** How fast the front wheels turn (radians per second): keys are on or off, cars shouldn't be. */
	public static inline final wheelTurnRate = 7.0;

	/** How fast the accelerator goes down or up: from none to full in a quarter of a second. */
	public static inline final throttleRate = 4.0;

	// ---- Tyres ----

	/**
	 * How hard each axle's tyres can push sideways, as a share of the weight
	 * on them (1.6 means 1.6 g). Off the power the rear grips a little more
	 * than the front, so a car pushed too far runs wide and settles; on the
	 * power the rear loses some grip (`rearGripLostToThrottle`) and the tail
	 * can drift round.
	 */
	public static inline final frontGrip = 1.6;
	public static inline final rearGrip = 1.7;

	/**
	 * Once a tyre is really sliding it grips less than at its best: this
	 * share, reached at twice the slip of its best grip. That is what lets a
	 * drift happen, and makes it something to hold rather than a fixed line.
	 */
	public static inline final gripWhenSliding = 0.8;

	/**
	 * The slip angle (between where a tyre points and where it is going) at
	 * which it grips hardest. Below it, grip grows with slip; beyond it the
	 * tyre slides, holding on at its limit.
	 */
	public static final slipAtMostGrip = degrees(7);

	/** Full throttle takes this share of the rear grip away, so the tail can be kicked out (power oversteer). */
	public static inline final rearGripLostToThrottle = 0.2;

	/**
	 * A helping hand, as arcade racers have: how quickly (per second) the
	 * car's turning settles towards what its front wheels ask for. It stops a
	 * small correction growing into a spin, and makes countersteering catch a
	 * slide; drift is still there, but it goes where the wheels point.
	 */
	public static inline final steadying = 4.0;

	/**
	 * Steering held at full lock lets the car turn this much more than its
	 * grip can hold (0.25 is a quarter more), building from `extraTurnFromLock`
	 * of full lock. Keys and touch reach full lock by being held.
	 */
	public static inline final extraTurnAtFullLock = 0.25;
	public static inline final extraTurnFromLock = 0.75;

	// ---- Weight shift (the flick) ----

	/** How long the body takes to roll its weight over to a new side, in seconds. */
	public static inline final weightRollsOverIn = 0.35;

	/**
	 * A full flick: the weight still leaning this hard one way (in g) times
	 * the wheels asking this hard the other (in g). A little right then hard
	 * left is about half of one; a hard right then hard left, all of one.
	 */
	public static inline final fullFlick = 1.2;

	/** The flick only counts once the car is turning the new way at least this fast (radians per second). */
	public static inline final flickOnceTurningAt = 0.3;

	/** At a full flick the rear tyres lose this share of their grip, and the steadying hand this share of its hold. */
	public static inline final rearGripLostInAFlick = 0.45;
	public static inline final steadyingLostInAFlick = 0.75;

	/**
	 * Below this speed (m/s) the tyre sums get jumpy, so the car rolls where
	 * its wheels point instead, blending into the tyre model as it speeds up.
	 */
	public static inline final tyreModelFromSpeed = 2.0;

	/** The most each axle's tyres can push sideways, in newtons. */
	public static final frontGripLimit = frontGrip * mass * gravity * frontWeightShare;
	public static final rearGripLimit = rearGrip * mass * gravity * rearWeightShare;
}
