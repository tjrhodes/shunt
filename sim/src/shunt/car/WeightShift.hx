package shunt.car;

import shunt.car.CarTuning as Tuning;
import shunt.maths.Numbers.keepBetween;
import shunt.maths.Numbers.signOf;

using shunt.car.CarFrame;

/**
 * The car's weight, rocking from side to side (Tom, 1 Nov: "turn right
 * slightly and then hard left, and it drifts, because I've chucked the
 * weight over").
 *
 * When a car turns, its weight leans onto the outside tyres; the body
 * takes a moment to roll over, so the lean lags behind the turn
 * (`Car.sidewaysLoad`). Throw the car one way and then hard the other, and
 * for a moment the weight is still over the old side while the wheels ask
 * for the new one: the tail goes light and steps out. That is the "flick"
 * (the Scandinavian flick, as rally drivers call it).
 *
 * So, while the weight is swinging across against the way the wheels ask
 * to turn, the rear tyres lose some grip, and the steadying hand lets go a
 * little so the slide can happen. Turning from straight has no swing at
 * all, so ordinary driving feels exactly as before.
 */
class WeightShift {
	/** Lets the weight roll a tick towards how hard the car is being pushed sideways now (in g, positive to the left). */
	public static function rollWithThe(car:Car, push:Push) {
		var pushedLeft = car.inCarTerms(push.force).y / (Tuning.mass * Tuning.gravity);
		var share = Math.min(1, Tick.seconds / Tuning.weightRollsOverIn);
		car.sidewaysLoad += (pushedLeft - car.sidewaysLoad) * share;
	}

	/**
	 * How hard the weight is swinging across right now, from 0 (not at all)
	 * to 1 (a full flick): the weight on one side while the wheels ask to
	 * turn the other way, the more of both the more swing; and only once
	 * the car has started to turn the new way. (Countersteering a slide
	 * also asks against the weight, but the car is still turning the old
	 * way then: that must stay a catch, not become a flick.)
	 */
	public static function swing(car:Car):Float {
		var wheelsAskLeft = CarMotion.spinOfRollingWheels(car) * car.forwardSpeed() / Tuning.gravity;
		var against = -car.sidewaysLoad * wheelsAskLeft;
		var turningTheNewWay = keepBetween(car.spin * signOf(wheelsAskLeft) / Tuning.flickOnceTurningAt, 0, 1);
		return keepBetween(against / Tuning.fullFlick, 0, 1) * turningTheNewWay;
	}
}
