package shunt.ai;

import shunt.ai.AiTuning as Ai;
import shunt.ai.DriverCharacter;
import shunt.car.Car;
import shunt.car.CarInput;
import shunt.car.CarTuning;
import shunt.car.Controls;
import shunt.car.Damage;
import shunt.maths.Numbers.keepBetween;
import shunt.maths.Numbers.signOf;
import shunt.maths.SeededRandom;
import shunt.maths.Vector;
import shunt.race.Race;
import shunt.track.Track;

using shunt.car.CarFrame;

/**
 * An AI driver (SPEC.md §7). It reads the race, and gives back a `CarInput`
 * exactly as a player's keyboard does: the race can't tell them apart.
 *
 * It aims at a point on the track a little way ahead (further at speed),
 * drives at the racing line's speed for where it is, goes round cars and oil
 * in its way, and, if it is aggressive, gives the car ahead a tap instead.
 * It remembers nothing between ticks, so copying a race copies its AI too.
 */
class AiDriver {
	public final character:DriverCharacter;
	final line:RacingLine;
	final seat:Int;

	public function new(character:DriverCharacter, line:RacingLine, seat:Int) {
		this.character = character;
		this.line = line;
		this.seat = seat;
	}

	/** What to do this tick: the pedals for the speed wanted, and the wheel towards the point aimed at. */
	public function inputFor(race:Race, number:Int):CarInput {
		var car = race.racer(number).car;
		var tooFastBy = car.speed() - wantedSpeed(race, number);
		return {
			throttle: tooFastBy < 0 ? 1 : 0,
			brake: keepBetween((tooFastBy - Ai.brakeWhenOverBy) / (Ai.fullBrakeWhenOverBy - Ai.brakeWhenOverBy), 0, 1),
			steer: steeringTowards(car, whereToAim(race, number)),
			recover: false
		};
	}

	/** The racing line's speed just ahead, at this driver's pace. */
	function wantedSpeed(race:Race, number:Int):Float {
		var justAhead = race.racer(number).trackIndex + 2;
		return line.speedAt(justAhead) * character.pace;
	}

	/**
	 * The steering that takes the car along a curve to the point aimed at
	 * ("pure pursuit": the arc through the car and the point). It also holds
	 * against any pull from a bent front.
	 */
	function steeringTowards(car:Car, aimAt:Vector):Float {
		var asTheCarSeesIt = car.inCarTerms(aimAt - car.position);
		var angleToIt = Math.atan2(asTheCarSeesIt.y, asTheCarSeesIt.x);
		var wheelAngleToTheLeft = Math.atan(2 * CarTuning.wheelbase * Math.sin(angleToIt) / Math.max(1, asTheCarSeesIt.length()));
		return keepBetween((-wheelAngleToTheLeft - Damage.steeringPull(car)) / Controls.mostSteeringNow(car), -1, 1);
	}

	/** A point on the track ahead, in the lane chosen; or, to an aggressive driver, the car in front's back corner. */
	function whereToAim(race:Race, number:Int):Vector {
		var car = race.racer(number).car;
		var target = carToBump(race, number);
		if (target != null) return backCornerToTap(target, car);
		var ahead = race.racer(number).trackIndex + Math.round((Ai.shortestLookAhead + car.speed() * Ai.secondsLookAhead) / Track.sampleSpacing);
		return race.track.sample(ahead).position + race.track.leftAt(ahead) * laneToTake(race, number, ahead);
	}

	/**
	 * Across the track: its favourite lane, unless a car or oil is in the way,
	 * when it goes round. Never too near the walls.
	 */
	function laneToTake(race:Race, number:Int, ahead:Int):Float {
		var room = race.track.sample(ahead).width / 2 - Ai.wallMargin;
		var lane = character.favouriteLane * Ai.widestFavouriteLane * room;
		for (thingInTheWay in carsAndOilAhead(race, number)) {
			if (Math.abs(lane - thingInTheWay) < Ai.passingGap) lane = thingInTheWay - signOf(thingInTheWay) * Ai.passingGap;
		}
		return keepBetween(lane, -room, room);
	}

	/** How far left of the centreline each car, and each oil patch it spots, ahead of it is. */
	function carsAndOilAhead(race:Race, number:Int):Array<Float> {
		return carsAhead(race, number).concat(oilAhead(race, number));
	}

	function carsAhead(race:Race, number:Int):Array<Float> {
		var mine = race.racer(number).trackIndex;
		var lanes:Array<Float> = [];
		for (other in 0...race.state.racers.length) {
			var theirs = race.racer(other);
			var isInTheWay = other != number && isAhead(race.track, mine, theirs.trackIndex, Ai.trafficAhead);
			if (isInTheWay) lanes.push(race.track.howFarLeft(theirs.car.position, theirs.trackIndex));
		}
		return lanes;
	}

	function oilAhead(race:Race, number:Int):Array<Float> {
		var mine = race.racer(number).trackIndex;
		var lanes:Array<Float> = [];
		for (patch in race.state.oil) {
			var patchIndex = race.track.nearestSampleNear(patch.position, mine, Math.round(Ai.oilLookAhead));
			var isInTheWay = spotsOil(patch.position) && isAhead(race.track, mine, patchIndex, Ai.oilLookAhead);
			if (isInTheWay) lanes.push(race.track.howFarLeft(patch.position, patchIndex));
		}
		return lanes;
	}

	/** For an aggressive driver: the car just in front, in its lane, if there is one. */
	function carToBump(race:Race, number:Int):Null<Car> {
		if (character.aggression < Ai.bumpsFromAggression) return null;
		var me = race.racer(number);
		var myLane = race.track.howFarLeft(me.car.position, me.trackIndex);
		for (other in 0...race.state.racers.length) {
			var them = race.racer(other);
			var inMyLane = Math.abs(race.track.howFarLeft(them.car.position, them.trackIndex) - myLane) < Ai.trafficToTheSide;
			var justAhead = isAhead(race.track, me.trackIndex, them.trackIndex, Ai.trafficAhead);
			if (other != number && inMyLane && justAhead && them.ghostTicks == 0) return them.car;
		}
		return null;
	}

	/** The back corner of a car on the side nearer the bumper, where a tap turns it. */
	static function backCornerToTap(target:Car, bumper:Car):Vector {
		var side = signOf(target.inCarTerms(bumper.position - target.position).y);
		return target.spotUnder(new Vector(-CarTuning.length / 2, side * CarTuning.width / 3));
	}

	/** Whether one centreline sample is ahead of another, by no more than `withinMetres` (and more than nothing). */
	static function isAhead(track:Track, from:Int, to:Int, withinMetres:Float):Bool {
		var samplesAhead = (to - from + track.samples.length) % track.samples.length;
		return samplesAhead > 0 && samplesAhead * Track.sampleSpacing <= withinMetres;
	}

	/**
	 * Whether this driver spots an oil patch: a coin toss, weighted by its
	 * skill, that comes out the same every tick for the same patch.
	 */
	function spotsOil(where:Vector):Bool {
		var patchAndDriver = Std.int(where.x * 100) * 31 + Std.int(where.y * 100) * 17 + seat;
		var toss = SeededRandom.asFraction(SeededRandom.next(SeededRandom.startingFrom(patchAndDriver)));
		return toss < 0.5 + character.skill / 2;
	}
}
