package shunt.race;

import shunt.car.Car;
import shunt.maths.SeededRandom;
import shunt.race.Race.RaceSettings;
import shunt.race.RaceState.Racer;
import shunt.track.Track;

/** Lining the cars up behind the start line, lights red. */
class StartingGrid {
	public static function lineUp(track:Track, settings:RaceSettings):RaceState {
		return {
			tick: 0,
			phase: Lights,
			laps: settings.laps,
			racers: [for (number in 0...settings.cars) racerOnTheGrid(track, number)],
			order: [for (number in 0...settings.cars) number],
			oil: [],
			random: SeededRandom.startingFrom(settings.seed),
			endTick: -1
		};
	}

	/** Each car on its own row, further back for each, alternating left and right of the centreline. */
	static function racerOnTheGrid(track:Track, number:Int):Racer {
		var index = track.sampleIndexBehindTheLine(RaceTuning.firstRowBehindTheLine + number * RaceTuning.rowGap);
		var side = number % 2 == 0 ? 1 : -1;
		var spot = track.sample(index).position + track.leftAt(index) * (side * track.sample(index).width / 4);
		return freshRacer(Cars.parkedAt(spot, track.sample(index).direction.angle()), index);
	}

	/**
	 * A racer before the start. The grid is behind the line, so the first
	 * time across it starts lap 1: as if every checkpoint had been passed.
	 */
	static function freshRacer(car:Car, trackIndex:Int):Racer {
		return {
			car: car,
			lapsStarted: 0,
			nextCheckpoint: RaceTuning.checkpoints,
			trackIndex: trackIndex,
			lapStartTick: 0,
			lapTicks: [],
			finishTick: -1,
			troubleTicks: 0,
			ghostTicks: 0,
			oilTicks: -1,
			timesPutBack: 0
		};
	}
}
