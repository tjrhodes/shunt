package shunt.car;

import shunt.car.CarTuning as Tuning;
import shunt.car.DamageTuning as Harm;
import shunt.maths.Numbers.keepBetween;
import shunt.maths.Numbers.signOf;
import shunt.maths.Vector;

using shunt.car.CarFrame;

/**
 * How battered each side of a car is, from 0 (new) to 100 (wrecked).
 * Never changed once made (a hit makes a new one), so copies of a car can
 * share it, like arrows.
 */
typedef DamageZones = {
	final front:Float;
	final rear:Float;
	final left:Float;
	final right:Float;
}

/** The four sides of a car a hit can land on. */
enum abstract Zone(String) {
	var Front = "front";
	var Rear = "rear";
	var Left = "left";
	var Right = "right";
}

/**
 * Damage: how hard hits batter a car, and what a battered car can no longer
 * do as well (SPEC.md §4b). All the numbers are in `DamageTuning`.
 */
class Damage {
	public static final none:DamageZones = {front: 0, rear: 0, left: 0, right: 0};

	/**
	 * The car's damage after a hit that changed its speed by `speedChange`
	 * (m/s) at a point on its body. Bumps under the harmless limit change
	 * nothing; harder hits batter the side that was hit.
	 */
	public static function afterHit(car:Car, speedChange:Float, point:Vector):DamageZones {
		var points = (speedChange - Harm.harmlessBelow) * Harm.pointsPerSpeedChange;
		if (points <= 0) return car.damage;
		return withMore(car.damage, zoneFacing(car, point), points);
	}

	/**
	 * Which side of the car a point is on: measured against the car's size,
	 * is it further forwards or backwards, or further to a side?
	 */
	public static function zoneFacing(car:Car, point:Vector):Zone {
		var fromTheMiddle = car.inCarTerms(point - car.position);
		var lengthways = fromTheMiddle.x / Tuning.length;
		var sideways = fromTheMiddle.y / Tuning.width;
		if (Math.abs(lengthways) >= Math.abs(sideways)) return lengthways > 0 ? Front : Rear;
		return sideways > 0 ? Left : Right;
	}

	/** The same damage, with more points on one zone (up to wrecked). */
	static function withMore(zones:DamageZones, zone:Zone, points:Float):DamageZones {
		function addedIf(isThisZone:Bool, value:Float) return isThisZone ? Math.min(Harm.wrecked, value + points) : value;
		return {
			front: addedIf(zone == Front, zones.front),
			rear: addedIf(zone == Rear, zones.rear),
			left: addedIf(zone == Left, zones.left),
			right: addedIf(zone == Right, zones.right)
		};
	}

	/**
	 * One number for how damaged the car is: half its worst zone and half the
	 * average of all four, so one smashed corner matters.
	 */
	public static function overall(car:Car):Float {
		var zones = car.damage;
		var worst = Math.max(Math.max(zones.front, zones.rear), Math.max(zones.left, zones.right));
		var average = (zones.front + zones.rear + zones.left + zones.right) / 4;
		return (worst + average) / 2;
	}

	/** How much of its engine and top speed a car still has: all when new, three quarters when wrecked. */
	public static function speedShare(car:Car):Float {
		return 1 - Harm.mostSpeedLost * overall(car) / Harm.wrecked;
	}

	/** How far a bent front pulls the wheels (radians, right is positive) towards its more damaged side. */
	public static function steeringPull(car:Car):Float {
		var howBent = shareOfTheWayAbove(car.damage.front, Harm.steeringPullsFrom);
		var whichWay = signOf(car.damage.right - car.damage.left);
		return Harm.mostSteeringPull * howBent * whichWay;
	}

	/** How much of its steering a car still has: all of it, until the front is badly damaged. */
	public static function steeringShare(car:Car):Float {
		return 1 - Harm.mostSteeringLost * shareOfTheWayAbove(car.damage.front, Harm.steeringWeakensFrom);
	}

	/** Badly damaged cars leak oil. */
	public static function isLeakingOil(car:Car):Bool {
		return overall(car) > Harm.leaksOilFrom;
	}

	/** How far a zone's damage is between a starting point and wrecked: 0 below it, 1 when wrecked. */
	public static function shareOfTheWayAbove(damage:Float, from:Float):Float {
		return keepBetween((damage - from) / (Harm.wrecked - from), 0, 1);
	}
}
