package shunt.race;

import shunt.maths.Vector;
import shunt.race.RaceState.Racer;

/** Who is where, and when the race is over (SPEC.md §6). */
class Standings {
	public static function update(race:Race) {
		race.state.order = leaderFirst(race);
		endTheRaceWhenItIsTime(race);
	}

	/**
	 * How far a car has got: whole laps started, plus how far round this one.
	 * On the grid (behind the line) a car is nearly a lap round "lap 0".
	 */
	public static function progress(race:Race, racer:Racer):Float {
		return racer.lapsStarted * race.track.length + race.track.sample(racer.trackIndex).distance;
	}

	/** Finished cars first, in the order they finished; then whoever has got furthest; then grid order. */
	static function leaderFirst(race:Race):Array<Int> {
		var order = [for (number in 0...race.state.racers.length) number];
		order.sort((first, second) -> comesFirst(race, first, second));
		return order;
	}

	/** Negative if `first` is ahead of `second`, positive if behind (how a sort wants it). */
	static function comesFirst(race:Race, first:Int, second:Int):Int {
		var a = race.racer(first);
		var b = race.racer(second);
		if (a.finishTick >= 0 || b.finishTick >= 0) return finishedFirst(a, b, first - second);
		var gap = progress(race, b) - progress(race, a);
		return gap != 0 ? (gap > 0 ? 1 : -1) : first - second;
	}

	/** Between two cars where at least one has finished: the one that finished (earlier) is ahead. */
	static function finishedFirst(a:Racer, b:Racer, gridOrder:Int):Int {
		if (a.finishTick < 0) return 1;
		if (b.finishTick < 0) return -1;
		return a.finishTick != b.finishTick ? a.finishTick - b.finishTick : gridOrder;
	}

	/** The race ends when everyone has finished, or when the time after the leader runs out. */
	static function endTheRaceWhenItIsTime(race:Race) {
		var state = race.state;
		if (state.phase != Racing || state.endTick < 0) return;
		var everyoneIn = Lambda.foreach(state.racers, racer -> racer.finishTick >= 0);
		if (!everyoneIn && state.tick < state.endTick) return;
		state.phase = Finished;
		race.tell(RaceOver, -1, -1, Vector.nothing(), 0);
	}
}
