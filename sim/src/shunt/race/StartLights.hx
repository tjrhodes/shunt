package shunt.race;

import shunt.maths.Vector;
import shunt.race.RaceTuning as Rules;

/** The start lights: red, red, red, green (SPEC.md §6). */
class StartLights {
	static final ticksBetweenLights = Tick.ticksIn(Rules.secondsBetweenLights);

	/** The tick the lights go green: a gap after the last red one. */
	public static final greenTick = ticksBetweenLights * (Rules.redLights + 1);

	/** How many red lights are showing (0 before the first, and once they are green). */
	public static function redLightsShowing(state:RaceState):Int {
		if (state.phase != Lights) return 0;
		return Std.int(Math.min(Rules.redLights, Math.floor(state.tick / ticksBetweenLights)));
	}

	/** Puts the next light on, or turns them green and starts the race, when it is time. */
	public static function changeWhenItIsTime(race:Race) {
		var state = race.state;
		if (state.phase != Lights || state.tick % ticksBetweenLights != 0) return;
		if (state.tick < greenTick) {
			race.tell(LightOn, -1, -1, Vector.nothing(), redLightsShowing(state));
			return;
		}
		state.phase = Racing;
		race.tell(Green, -1, -1, Vector.nothing(), 0);
	}
}
