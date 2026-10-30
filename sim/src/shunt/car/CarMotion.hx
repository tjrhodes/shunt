package shunt.car;

import shunt.car.CarTuning as Tuning;
import shunt.maths.Numbers.stepTowards;
import shunt.maths.Numbers.wrapAngle;
import shunt.maths.Vector;

using shunt.car.CarFrame;

/**
 * Moving a car on by one tick, once all the pushes on it are known.
 */
class CarMotion {
	/**
	 * First the pushes change how fast the car moves and spins; then the new
	 * speed and spin move it. (Doing it in that order, "semi-implicit Euler",
	 * keeps the car steady where the other order slowly gains energy.)
	 */
	public static function moveOneTick(car:Car, push:Push) {
		car.velocity = car.velocity + push.force * (Tick.seconds / Tuning.mass);
		car.spin += push.twist / Tuning.turningInertia * Tick.seconds;
		rollWhereTheWheelsPointWhenSlow(car);
		car.position = car.position + car.velocity * Tick.seconds;
		car.heading = wrapAngle(car.heading + car.spin * Tick.seconds);
	}

	/**
	 * At a crawl, the tyre model (in `Tyres`) fades out, because its sums go
	 * wild near zero speed. Instead the car behaves like a toy pushed by hand:
	 * its tyres scrub off any sideways sliding, and it turns exactly as its
	 * wheels point. Both are limited by how hard the tyres can grip, so a car
	 * shoved while stopped still moves, and the change is smooth.
	 */
	static function rollWhereTheWheelsPointWhenSlow(car:Car) {
		var crawlShare = 1 - Tyres.tyreModelShare(car);
		if (crawlShare == 0) return;
		var scrubThisTick = Tyres.mostSidewaysSlowing() * Tick.seconds * crawlShare;
		var sideways = stepTowards(car.sidewaysSpeed(), 0, scrubThisTick);
		car.velocity = car.inWorldTerms(new Vector(car.forwardSpeed(), sideways));
		var turnThisTick = Tyres.mostSpinSlowing() * Tick.seconds * crawlShare;
		car.spin = stepTowards(car.spin, spinOfRollingWheels(car), turnThisTick);
	}

	/**
	 * How fast a car turns when its tyres don't slide at all: its rear axle
	 * follows its front on a circle set by the wheelbase and the wheel angle.
	 * Wheels turned right make the car turn clockwise, so the sign is turned round.
	 */
	static function spinOfRollingWheels(car:Car):Float {
		return -car.forwardSpeed() * Math.tan(car.wheelAngle) / Tuning.wheelbase;
	}
}
