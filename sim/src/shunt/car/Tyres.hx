package shunt.car;

import shunt.car.CarTuning as Tuning;
import shunt.maths.Numbers.keepBetween;
import shunt.maths.Numbers.partWay;
import shunt.maths.Numbers.signOf;
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
	/** The push and twist from all four tyres together, on whatever ground they are on. */
	public static function grip(car:Car, ground:Ground):Push {
		var bothAxles = frontAxleGrip(car, ground).plus(rearAxleGrip(car, ground));
		return bothAxles.times(tyreModelShare(car));
	}

	/**
	 * The front wheels are turned, so their own "forwards" and "left" are
	 * turned too: the slide is measured, and the push given, along them.
	 */
	static function frontAxleGrip(car:Car, ground:Ground):Push {
		var wheelForwards = new Vector(Math.cos(car.wheelAngle), -Math.sin(car.wheelAngle));
		var wheelLeft = wheelForwards.turnedLeft();
		var axleVelocity = new Vector(car.forwardSpeed(), car.sidewaysSpeed() + Tuning.frontAxleAhead * car.spin);
		var gripLimit = Tuning.frontGripLimit * gripUnderAxle(car, ground, Tuning.frontAxleAhead);
		var sidewaysPush = pushAgainstSliding(axleVelocity.along(wheelLeft), axleVelocity.along(wheelForwards), gripLimit);
		var pushInCarTerms = wheelLeft * sidewaysPush;
		return new Push(car.inWorldTerms(pushInCarTerms), Tuning.frontAxleAhead * pushInCarTerms.y);
	}

	/** The rear wheels point straight ahead; spinning swings them sideways, the opposite way to the front. */
	static function rearAxleGrip(car:Car, ground:Ground):Push {
		var slidingLeft = car.sidewaysSpeed() - Tuning.rearAxleBehind * car.spin;
		var gripLimit = rearGripLimitNow(car) * gripUnderAxle(car, ground, -Tuning.rearAxleBehind);
		var sidewaysPush = pushAgainstSliding(slidingLeft, car.forwardSpeed(), gripLimit);
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
		return -gripLimit * signOf(slipAngle) * shareOfGripAt(Math.abs(slipAngle));
	}

	/**
	 * How much of its grip a tyre gives at a slip angle: growing to all of it
	 * at its best angle, then falling away to its sliding grip by twice that.
	 */
	static function shareOfGripAt(slipAngle:Float):Float {
		var best = Tuning.slipAtMostGrip;
		if (slipAngle <= best) return slipAngle / best;
		return partWay(1, Tuning.gripWhenSliding, keepBetween((slipAngle - best) / best, 0, 1));
	}

	/** How much grip the ground gives under an axle (oil takes most of it), given how far ahead of the middle the axle is. */
	static function gripUnderAxle(car:Car, ground:Ground, howFarAhead:Float):Float {
		return ground.gripAt(car.spotUnder(new Vector(howFarAhead, 0)));
	}

	/**
	 * The accelerator takes some of the rear tyres' grip, to spin the wheels:
	 * that is power oversteer. Weight swinging across takes some too: the flick.
	 */
	static function rearGripLimitNow(car:Car):Float {
		var lostToThrottle = Tuning.rearGripLostToThrottle * car.throttle;
		var lostToTheFlick = Tuning.rearGripLostInAFlick * WeightShift.swing(car);
		return Tuning.rearGripLimit * (1 - lostToThrottle) * (1 - lostToTheFlick);
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
