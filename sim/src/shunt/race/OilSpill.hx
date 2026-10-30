package shunt.race;

import shunt.car.CarTuning;
import shunt.car.Damage;
import shunt.car.DamageTuning as Oil;
import shunt.car.Ground;
import shunt.maths.Vector;
import shunt.race.RaceState.OilPatch;

using shunt.car.CarFrame;

/**
 * Oil: badly damaged cars drop it now and then, it makes tyres lose most of
 * their grip, and it dries up after a while (SPEC.md §4b).
 */
class OilSpill {
	/** Every leaking car counts down to its next drop; every patch dries a little. */
	public static function leakAndDryUp(race:Race) {
		for (number in 0...race.state.racers.length) leakIfBadlyDamaged(race, number);
		for (patch in race.state.oil) patch.ticksLeft--;
		race.state.oil = race.state.oil.filter(patch -> patch.ticksLeft > 0);
	}

	/** The ground of the track with its oil: grip is lost wherever there is a patch. */
	public static function groundWithOil(oil:Array<OilPatch>):Ground {
		return {gripAt: spot -> Lambda.fold(oil, (patch, grip) -> Math.min(grip, gripOnPatch(patch, spot)), 1.0)};
	}

	/** How fresh a patch is: 1 until it starts to fade, then down to 0 as it dries up. */
	public static function freshness(patch:OilPatch):Float {
		return Math.min(1, patch.ticksLeft / Tick.ticksIn(Oil.oilFadesOver));
	}

	/** The grip at a spot on or off a patch: on it, less grip the fresher the oil. */
	static function gripOnPatch(patch:OilPatch, spot:Vector):Float {
		if (spot.distanceTo(patch.position) > Oil.oilPatchRadius) return 1;
		return 1 - (1 - Oil.gripOnOil) * freshness(patch);
	}

	/** A badly damaged car counts down to its next drop of oil; one that isn't leaking doesn't count. */
	static function leakIfBadlyDamaged(race:Race, number:Int) {
		var racer = race.racer(number);
		if (!Damage.isLeakingOil(racer.car)) {
			racer.oilTicks = -1;
			return;
		}
		if (racer.oilTicks < 0) racer.oilTicks = ticksToNextDrop(race, number);
		racer.oilTicks--;
		if (racer.oilTicks > 0) return;
		dropOil(race, number);
		racer.oilTicks = ticksToNextDrop(race, number);
	}

	/** A random gap between the shortest and longest, more often short the worse the damage. */
	static function ticksToNextDrop(race:Race, number:Int):Int {
		var howBad = Damage.shareOfTheWayAbove(Damage.overall(race.racer(number).car), Oil.leaksOilFrom);
		var shareOfTheLongestExtra = race.nextRandomFraction() * (1 - howBad / 2);
		return Tick.ticksIn(Oil.shortestOilGap + (Oil.longestOilGap - Oil.shortestOilGap) * shareOfTheLongestExtra);
	}

	/** A patch under the car's back bumper. If there are too many, the oldest goes. */
	static function dropOil(race:Race, number:Int) {
		var car = race.racer(number).car;
		var underTheBackBumper = car.spotUnder(new Vector(-CarTuning.length / 2, 0));
		race.state.oil.push({position: underTheBackBumper, ticksLeft: Tick.ticksIn(Oil.oilLasts)});
		if (race.state.oil.length > Oil.mostOilPatches) race.state.oil.shift();
		race.tell(OilDropped, number, -1, underTheBackBumper, 0);
	}
}
