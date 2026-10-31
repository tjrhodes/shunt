package feel;

import shunt.car.Car;
import shunt.maths.Numbers.keepBetween;

using shunt.car.CarFrame;

/**
 * How hard a car's tyres are sliding, read from the simulation, for
 * everything that shows or sounds a slide: skid marks, tyre smoke, squeal.
 * Worked out here once, so they all agree.
 */
class Slide {
	/** Sliding sideways slower than this (m/s) is just a tyre working: no marks, no squeal. */
	static inline final quietBelow = 2.0;

	/** Sliding sideways this fast or more is an all-out slide. */
	static inline final allOutFrom = 9.0;

	/** 0 when rolling true, up to 1 in an all-out slide. */
	public static function strength(car:Car):Float {
		return keepBetween((Math.abs(car.sidewaysSpeed()) - quietBelow) / (allOutFrom - quietBelow), 0, 1);
	}
}
