package shunt.race;

import shunt.maths.Vector;

/** What kind of thing happened. */
enum abstract EventKind(String) {
	var LightOn = "lightOn";
	var Green = "green";
	var CarHit = "carHit";
	var WallHit = "wallHit";
	var LapStarted = "lapStarted";
	var Finished = "finished";
	var OilDropped = "oilDropped";
	var PutBack = "putBack";
	var RaceOver = "raceOver";
}

/**
 * Something that happened during a tick, for sound, sparks and the HUD to
 * react to. Not part of the race's state: the race doesn't need to remember
 * them.
 */
typedef RaceEvent = {
	final kind:EventKind;

	/** The racer it happened to (-1 for the whole race). */
	final racer:Int;

	/** The other racer, in a car-to-car hit (-1 otherwise). */
	final other:Int;

	/** Where it happened (the racer's position, if nowhere more exact). */
	final point:Vector;

	/** How strong: for hits, the change of speed in m/s; otherwise 0. */
	final strength:Float;
}
