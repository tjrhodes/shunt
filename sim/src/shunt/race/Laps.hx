package shunt.race;

import shunt.race.RaceState.Racer;
import shunt.race.RaceTuning as Rules;
import shunt.track.Track;

/**
 * Following each car round the lap: where it is on the track, which
 * checkpoints it has passed, and counting laps (SPEC.md §6).
 */
class Laps {
	/** How many centreline samples away a car can be from where it was last seen. */
	public static final searchReach = Math.round(Rules.trackSearchReach / Track.sampleSpacing);

	/** Finds the car on the track, ticks off a checkpoint if it is at one, and counts a lap if it crossed the line. */
	public static function followProgress(race:Race, number:Int) {
		var racer = race.racer(number);
		var before = racer.trackIndex;
		racer.trackIndex = race.track.nearestSampleNear(racer.car.position, before, searchReach);
		passCheckpointIfThere(race.track, racer);
		if (crossedTheLineForwards(race.track, before, racer.trackIndex)) crossTheLine(race, number);
	}

	/** Laps finished: one fewer than laps started (never fewer than none). */
	public static function lapsDone(racer:Racer):Int {
		return Std.int(Math.max(0, racer.lapsStarted - 1));
	}

	/** The centreline sample where a checkpoint is (checkpoint 0 is the start line). */
	public static function checkpointSample(track:Track, checkpoint:Int):Int {
		return Math.round(track.samples.length * checkpoint / Rules.checkpoints);
	}

	/** If the car has just reached its next checkpoint, it moves on to the one after. */
	static function passCheckpointIfThere(track:Track, racer:Racer) {
		if (racer.nextCheckpoint >= Rules.checkpoints) return;
		var pastIt = racer.trackIndex - checkpointSample(track, racer.nextCheckpoint);
		if (pastIt >= 0 && pastIt < searchReach) racer.nextCheckpoint++;
	}

	/** Going from just before the line (the end of the samples) to just after it (the start). */
	static function crossedTheLineForwards(track:Track, before:Int, after:Int):Bool {
		return before > track.samples.length - searchReach && after < searchReach;
	}

	/**
	 * Crossing the line counts only after every checkpoint, in order. Then the
	 * last lap's time is kept, a new lap starts, or the car has finished.
	 */
	static function crossTheLine(race:Race, number:Int) {
		var racer = race.racer(number);
		if (racer.finishTick >= 0 || racer.nextCheckpoint < Rules.checkpoints) return;
		var tick = race.state.tick;
		if (racer.lapsStarted > 0) racer.lapTicks.push(tick - racer.lapStartTick);
		racer.lapsStarted++;
		racer.lapStartTick = tick;
		racer.nextCheckpoint = 1;
		if (lapsDone(racer) >= race.state.laps) finish(race, number);
		else race.tell(LapStarted, number, -1, racer.car.position, racer.lapsStarted);
	}

	/** The car has done every lap. The first to finish starts the clock on everyone else. */
	static function finish(race:Race, number:Int) {
		var racer = race.racer(number);
		racer.finishTick = race.state.tick;
		race.tell(Finished, number, -1, racer.car.position, 0);
		if (race.state.endTick < 0) race.state.endTick = race.state.tick + Tick.ticksIn(Rules.secondsToFinishAfterTheLeader);
	}
}
