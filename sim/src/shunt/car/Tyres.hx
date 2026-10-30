package shunt.car;

import shunt.car.CarTuning as Tuning;
import shunt.maths.Numbers.keepBetween;
import shunt.maths.Vector;

using shunt.car.CarFrame;

/**
 * The tyres: what makes a car go round corners instead of straight on, and
 * what makes it slide when asked for too much.
 *
 * Each axle is treated as one wide tyre (a "bicycle model"). A tyre rolls
 * freely along the way it points but fights being dragged sideways: the
 * faster it slides sideways, the harder it pushes back, until it can't grip
 * any more, and then it slides, still pushing at its limit. Because the
 * front pushes ahead of the centre of mass and the rear behind it, their
 * pushes also turn the car.
 */
class Tyres {
	/** The push and twist from all four tyres together. */
	public static function grip(car:Car):Push {
		var bothAxles = frontAxleGrip(car).plus(rearAxleGrip(car));
		return bothAxles.times(tyreModelShare(car));
	}

	/**
	 * The front wheels are turned, so their own "forwards" and "left" are
	 * turned too: the slide is measured, and the push given, along them.
	 */
	static function frontAxleGrip(car:Car):Push {
		var wheelForwards = new Vector(Math.cos(car.wheelAngle), -Math.sin(car.wheelAngle));
		var wheelLeft = wheelForwards.turnedLeft();
		var axleVelocity = new Vector(car.forwardSpeed(), car.sidewaysSpeed() + Tuning.frontAxleAhead * car.spin);
		var sidewaysPush = pushAgainstSliding(axleVelocity.along(wheelLeft), axleVelocity.along(wheelForwards), Tuning.frontGripLimit);
		var pushInCarTerms = wheelLeft * sidewaysPush;
		return new Push(car.inWorldTerms(pushInCarTerms), Tuning.frontAxleAhead * pushInCarTerms.y);
	}

	/** The rear wheels point straight ahead; spinning swings them sideways, the opposite way to the front. */
	static function rearAxleGrip(car:Car):Push {
		var slidingLeft = car.sidewaysSpeed() - Tuning.rearAxleBehind * car.spin;
		var sidewaysPush = pushAgainstSliding(slidingLeft, car.forwardSpeed(), rearGripLimitNow(car));
		var pushInWorldTerms = car.inWorldTerms(new Vector(0, sidewaysPush));
		return new Push(pushInWorldTerms, -Tuning.rearAxleBehind * sidewaysPush);
	}

	/**
	 * The heart of it. The slip angle is the angle between where a tyre is
	 * rolling and where it is actually going. The push grows with that angle
	 * up to the tyre's grip limit, then stays at the limit: that is a slide.
	 * It always pushes against the slide, so the sign is turned round.
	 */
	static function pushAgainstSliding(slidingLeft:Float, rollingForwards:Float, gripLimit:Float):Float {
		var slipAngle = Math.atan2(slidingLeft, Math.abs(rollingForwards));
		var shareOfGrip = keepBetween(slipAngle / Tuning.slipAtMostGrip, -1, 1);
		return -gripLimit * shareOfGrip;
	}

	/** The accelerator takes some of the rear tyres' grip, to spin the wheels: that is power oversteer. */
	static function rearGripLimitNow(car:Car):Float {
		return Tuning.rearGripLimit * (1 - Tuning.rearGripLostToThrottle * car.throttle);
	}

	/**
	 * How much the tyre model counts: nothing at a standstill, all of it from
	 * `tyreModelFromSpeed` up. Below that, `CarMotion` rolls the car where its
	 * wheels point instead (the slip sums go wild near zero speed).
	 */
	public static function tyreModelShare(car:Car):Float {
		return keepBetween(car.speed() / Tuning.tyreModelFromSpeed, 0, 1);
	}

	/** The fastest the tyres together can stop the car sliding sideways (metres per second, per second). */
	public static function mostSidewaysSlowing():Float {
		return (Tuning.frontGripLimit + Tuning.rearGripLimit) / Tuning.mass;
	}

	/** The fastest the tyres together can stop the car spinning (radians per second, per second). */
	public static function mostSpinSlowing():Float {
		var twistFront = Tuning.frontGripLimit * Tuning.frontAxleAhead;
		var twistRear = Tuning.rearGripLimit * Tuning.rearAxleBehind;
		return (twistFront + twistRear) / Tuning.turningInertia;
	}
}
