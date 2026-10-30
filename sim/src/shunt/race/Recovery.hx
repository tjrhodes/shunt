package shunt.race;

import shunt.car.Car;
import shunt.car.CarInput;
import shunt.race.RaceTuning as Rules;

using shunt.car.CarFrame;

/**
 * Getting stuck or turned-round cars going again (SPEC.md §1): after a few
 * seconds of trouble, or when the driver asks, the car is put back on the
 * centreline, facing the right way, and passes through other cars for a
 * moment so it isn't put straight into one.
 */
class Recovery {
	public static function helpIfInTrouble(race:Race, number:Int, input:CarInput) {
		var racer = race.racer(number);
		if (racer.ghostTicks > 0) racer.ghostTicks--;
		if (race.state.phase != Racing || racer.finishTick >= 0) {
			racer.troubleTicks = 0;
			return;
		}
		racer.troubleTicks = isInTrouble(race, number) ? racer.troubleTicks + 1 : 0;
		var askedForHelp = input.recover && racer.ghostTicks == 0;
		if (askedForHelp || racer.troubleTicks >= Tick.ticksIn(Rules.secondsInTroubleBeforeHelp)) putBackOnTrack(race, number);
	}

	/** Stuck (hardly moving), or facing back the way it came. */
	static function isInTrouble(race:Race, number:Int):Bool {
		var racer = race.racer(number);
		var raceDirection = race.track.sample(racer.trackIndex).direction;
		var isStuck = racer.car.speed() < Rules.stuckBelowSpeed;
		var isFacingTheWrongWay = racer.car.noseDirection().along(raceDirection) < Rules.wrongWayBelow;
		return isStuck || isFacingTheWrongWay;
	}

	/** On the centreline where it was, facing the right way, rolling at walking pace, as battered as before. */
	static function putBackOnTrack(race:Race, number:Int) {
		var racer = race.racer(number);
		var here = race.track.sample(racer.trackIndex);
		var car = Cars.parkedAt(here.position, here.direction.angle());
		car.velocity = here.direction * Rules.speedWhenPutBack;
		car.damage = racer.car.damage;
		racer.car = car;
		racer.ghostTicks = Tick.ticksIn(Rules.secondsAsAGhost);
		racer.troubleTicks = 0;
		racer.timesPutBack++;
		race.tell(PutBack, number, -1, here.position, 0);
	}
}
