package shunt.race;

import haxe.Json;
import shunt.car.CarInput;
import shunt.car.Driving;
import shunt.maths.SeededRandom;
import shunt.maths.Vector;
import shunt.race.RaceEvent.EventKind;
import shunt.race.RaceState.Phase;
import shunt.race.RaceState.Racer;
import shunt.track.Track;

/** How a race is set up. */
typedef RaceSettings = {
	final cars:Int;
	final laps:Int;
	final seed:Int;
}

/**
 * A race: a track, some cars on it, and the rules (SPEC.md §3 and §6).
 *
 * Every tick it is given one input per car, from wherever they come
 * (keyboard, gamepad, AI, network); it can't tell which. Everything it
 * knows is in `state`, plain data that can be copied and put back.
 */
class Race {
	public final track:Track;
	public var state(default, null):RaceState;

	/** What happened during the last tick. */
	public var events(default, null):Array<RaceEvent> = [];

	public function new(track:Track, settings:RaceSettings) {
		this.track = track;
		state = StartingGrid.lineUp(track, settings);
	}

	/** Moves the race on one tick: the whole story of a tick, in order. */
	public function step(inputs:Array<CarInput>) {
		events = [];
		state.tick++;
		StartLights.changeWhenItIsTime(this);
		driveEveryCar(inputs);
		Bumping.sortOutEveryHit(this);
		for (number in 0...state.racers.length) Laps.followProgress(this, number);
		for (number in 0...state.racers.length) Recovery.helpIfInTrouble(this, number, inputFor(number, inputs));
		OilSpill.leakAndDryUp(this);
		Standings.update(this);
	}

	/** Every car drives on, on the track with its oil: unless the lights are still red, when they are held on the grid. */
	function driveEveryCar(inputs:Array<CarInput>) {
		if (state.phase == Lights) return;
		var ground = OilSpill.groundWithOil(state.oil);
		for (number in 0...state.racers.length) Driving.driveOneTick(racer(number).car, inputFor(number, inputs), ground);
	}

	/** A racer's input: what it asked for, or a gentle coast once it has finished. */
	function inputFor(number:Int, inputs:Array<CarInput>):CarInput {
		if (racer(number).finishTick >= 0) return finishedCoasting;
		return inputs[number] ?? CarInputs.nothingPressed;
	}

	static final finishedCoasting:CarInput = {
		throttle: 0,
		brake: RaceTuning.brakeWhenFinished,
		steer: 0,
		recover: false
	};

	public function racer(number:Int):Racer {
		return state.racers[number];
	}

	/** A copy of the whole state, sharing nothing with the race, to put back later. */
	public function copyState():RaceState {
		return Json.parse(Json.stringify(state));
	}

	/** Puts a copied state back, so the race carries on from there. */
	public function restoreState(saved:RaceState) {
		state = Json.parse(Json.stringify(saved));
	}

	/** Notes something that happened this tick. */
	public function tell(kind:EventKind, racer:Int, other:Int, point:Vector, strength:Float) {
		events.push({kind: kind, racer: racer, other: other, point: point, strength: strength});
	}

	/** The next number from the race's seeded random generator, from 0 up to 1. */
	public function nextRandomFraction():Float {
		state.random = SeededRandom.next(state.random);
		return SeededRandom.asFraction(state.random);
	}
}
