package hud;

import js.html.Element;
import shunt.race.Race;
import shunt.race.RaceState.Racer;
import shunt.race.StartLights;
import shunt.race.RaceTuning;

/**
 * What the player reads while racing (SPEC.md §1): their position and lap
 * in one corner, this lap's time and their best in the other, and the start
 * lights across the top. All read straight from the race's state.
 */
class Hud {
	/** The player's seat: the HUD is about them. */
	static inline final player = 0;

	final position:Element;
	final lap:Element;
	final thisLap:Element;
	final bestLap:Element;
	final lamps:Array<Element>;

	public function new(hud:Element) {
		var standing = Dom.make("div", "plate plate-standing", null, hud);
		position = figure(standing, Words.position);
		lap = figure(standing, Words.lap);
		var times = Dom.make("div", "plate plate-times", null, hud);
		thisLap = figure(times, Words.thisLap);
		bestLap = figure(times, Words.bestLap);
		var lights = Dom.make("div", "lights", null, hud);
		lamps = [for (_ in 0...RaceTuning.redLights) Dom.make("span", "lamp", null, lights)];
	}

	/** Brings every figure up to date with the race. */
	public function update(race:Race) {
		var me = race.racer(player);
		Dom.setText(position, Words.outOf(race.state.order.indexOf(player) + 1, race.state.racers.length));
		Dom.setText(lap, Words.outOf(Std.int(Math.max(1, Math.min(me.lapsStarted, race.state.laps))), race.state.laps));
		Dom.setText(thisLap, Words.raceTime(secondsIntoThisLap(race, me)));
		Dom.setText(bestLap, bestLapText(me));
		showLights(race);
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
	static function bestLapText(racer:Racer):String {
		if (racer.lapTicks.length == 0) return Words.noTimeYet;
		var fastest = Lambda.fold(racer.lapTicks, (ticks, best) -> Std.int(Math.min(best, ticks)), racer.lapTicks[0]);
		return Words.raceTime(fastest / Tick.perSecond);
	}

	/** A labelled figure in a plate; returns the element holding the figure. */
	static function figure(plate:Element, label:String):Element {
		var pair = Dom.make("div", "figure", null, plate);
		Dom.make("span", "figure-label", label, pair);
		return Dom.make("span", "figure-value", null, pair);
	}
}
