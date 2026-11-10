package hud;

import js.html.Element;
import shunt.race.Race;
import shunt.race.RaceState.Racer;
import shunt.race.StartLights;
import shunt.race.RaceTuning;

/**
 * What the people racing read (SPEC.md §1): a plate each with their
 * position, lap and damage, one in each corner of the screen; the start
 * lights across the top; and, when one person races alone, this lap's time
 * and their best. All read straight from the race's state.
 */
class Hud {
	final plates:Array<PlayerPlate>;
	final times:Element;
	final thisLap:Element;
	final bestLap:Element;
	final lamps:Array<Element>;

	/** The seat of the one person racing alone, whose lap times show; -1 when several race. */
	var timesFor = -1;

	public function new(hud:Element, seats:Int) {
		plates = [for (seat in 0...seats) new PlayerPlate(seat, hud)];
		times = Dom.make("div", "plate plate-times", null, hud);
		thisLap = figure(times, Words.thisLap);
		bestLap = figure(times, Words.bestLap);
		var lights = Dom.make("div", "lights", null, hud);
		lamps = [for (_ in 0...RaceTuning.redLights) Dom.make("span", "lamp", null, lights)];
	}

	/** Shows a plate for each of the seats our people drive, corner by corner in seat order; the lap times only for someone racing alone. */
	public function seat(people:Array<Int>) {
		for (seat in 0...plates.length) plates[seat].place(people.contains(seat), people.indexOf(seat), people.length > 1);
		timesFor = people.length == 1 ? people[0] : -1;
		times.hidden = timesFor < 0;
	}

	/** Brings every figure up to date with the race. */
	public function update(race:Race) {
		for (plate in plates) if (!plate.plate.hidden) plate.update(race);
		if (timesFor >= 0) showTimes(race.racer(timesFor), race);
		showLights(race);
	}

	function showTimes(racer:Racer, race:Race) {
		Dom.setText(thisLap, Words.raceTime(secondsIntoThisLap(race, racer)));
		Dom.setText(bestLap, bestLapText(racer));
	}

	/** Red lamps come on one by one; at green they all turn green, then go out once the cars are away. */
	function showLights(race:Race) {
		var reds = StartLights.redLightsShowing(race.state);
		var isGreen = race.state.phase == Racing && race.state.tick < StartLights.greenTick + Tick.ticksIn(RaceTuning.secondsBetweenLights);
		for (index in 0...lamps.length) {
			lamps[index].classList.toggle("is-red", index < reds);
			lamps[index].classList.toggle("is-green", isGreen);
		}
		lamps[0].parentElement.classList.toggle("is-out", race.state.phase != Lights && !isGreen);
	}

	/** The time on this lap so far; nothing until the first lap starts, and frozen once finished. */
	static function secondsIntoThisLap(race:Race, racer:Racer):Float {
		if (racer.lapsStarted == 0) return 0;
		var now = racer.finishTick >= 0 ? racer.finishTick : race.state.tick;
		return (now - racer.lapStartTick) / Tick.perSecond;
	}

	/** The fastest finished lap, or a dash before there is one. */
	public static function bestLapText(racer:Racer):String {
		if (racer.lapTicks.length == 0) return Words.noTimeYet;
		var fastest = Lambda.fold(racer.lapTicks, (ticks, best) -> Std.int(Math.min(best, ticks)), racer.lapTicks[0]);
		return Words.raceTime(fastest / Tick.perSecond);
	}

	/** A labelled figure in a plate; returns the element holding the figure. */
	public static function figure(plate:Element, label:String):Element {
		var pair = Dom.make("div", "figure", null, plate);
		Dom.make("span", "figure-label", label, pair);
		return Dom.make("span", "figure-value", null, pair);
	}
}
