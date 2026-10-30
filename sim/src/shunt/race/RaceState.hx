package shunt.race;

import shunt.car.Car;
import shunt.maths.Vector;

/** Where a race has got to. */
enum abstract Phase(String) {
	/** On the grid, lights red. */
	var Lights = "lights";

	var Racing = "racing";

	/** Everyone has finished, or the time after the leader ran out. */
	var Finished = "finished";
}

/** One car in a race, with everything the race knows about how it is doing. */
typedef Racer = {
	var car:Car;

	/** How many times it has started a lap by crossing the line (laps done is one fewer). */
	var lapsStarted:Int;

	/** The next checkpoint it must pass; `RaceTuning.checkpoints` means "the line is next". */
	var nextCheckpoint:Int;

	/** The centreline sample it is nearest. */
	var trackIndex:Int;

	/** The tick its current lap started, and how many ticks each finished lap took. */
	var lapStartTick:Int;
	var lapTicks:Array<Int>;

	/** The tick it finished on, or -1. */
	var finishTick:Int;

	/** How many ticks it has been stuck or facing the wrong way. */
	var troubleTicks:Int;

	/** Ticks left passing through other cars, after being put back on the track. */
	var ghostTicks:Int;

	/** Ticks until it next drops oil, or -1 when it isn't leaking. */
	var oilTicks:Int;

	/** How many times it has been put back on the track. */
	var timesPutBack:Int;
}

/** A patch of oil on the track. */
typedef OilPatch = {
	final position:Vector;
	var ticksLeft:Int;
}

/**
 * Everything about a race at one moment: plain data, so it can be copied,
 * compared, saved and sent (SPEC.md §3). The track is not in here: it never
 * changes, so it is kept beside the state, in `Race`.
 */
typedef RaceState = {
	var tick:Int;
	var phase:Phase;
	var laps:Int;
	var racers:Array<Racer>;

	/** Racer numbers, leader first. */
	var order:Array<Int>;

	var oil:Array<OilPatch>;

	/** The seeded random generator's state (`SeededRandom`). */
	var random:Int;

	/** The tick the race ends on, once the leader has finished; -1 until then. */
	var endTick:Int;
}
