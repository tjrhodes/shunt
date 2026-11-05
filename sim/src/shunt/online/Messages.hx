package shunt.online;

import shunt.car.CarInput;
import shunt.race.RaceState;

/**
 * Everything the browsers and the server say to each other: one name and
 * one shape per message, used by both sides, so they can never disagree
 * (SPEC.md §9). The server's TypeScript reads the names from here too.
 */
@:expose("Messages") @:keep
class Messages {
	// ---- From a browser ----

	/** "We are this many people": the browser asks for that many seats. */
	public static final takeSeats = "takeSeats";

	/** The host picks the track. */
	public static final chooseTrack = "chooseTrack";

	/** The host starts the race (or the next one). */
	public static final startRace = "startRace";

	/** A batch of the browser's inputs, numbered. */
	public static final inputs = "inputs";

	// ---- From the server ----

	/** Who is in the room and who sits where: sent whenever that changes. */
	public static final room = "room";

	/** A race begins: everything a browser needs to set up the very same race. */
	public static final raceStarts = "raceStarts";

	/** Where everything is now, many times a second. */
	public static final snapshot = "snapshot";
}

/**
 * What a browser asks for when it makes a room: a quick match or not, the
 * track to start on (Tom, 5 Nov: the one chosen on the cards, not always
 * the first), or a tournament's tracks. From a browser, so the room checks
 * it all.
 */
typedef RoomAsked = {
	final ?quick:Bool;
	final ?track:Dynamic;
	final ?tournament:Dynamic;
}

/** "We are this many people." */
typedef SeatsWanted = {
	final people:Int;
}

typedef TrackChoice = {
	final track:Int;
}

/**
 * Inputs from one browser: for each tick in turn, one input per seat it
 * drives (in seat order). The first is numbered `firstNumber`, the next one
 * more, and so on; the server says which number it has used up to.
 */
typedef InputBatch = {
	final firstNumber:Int;
	final ticks:Array<Array<CarInput>>;
}

/** One seat: the browser (by its session) and which of its people drives it; an empty owner is an AI driver. */
typedef SeatHolder = {
	final owner:String;
	final person:Int;
}

/** What a room is doing. */
enum abstract RoomPhase(String) {
	/** Waiting for the host to start. */
	var Gathering = "gathering";

	var Racing = "racing";

	/** A race has finished; its results show until the next one. */
	var Results = "results";
}

/** The room as everyone in it sees it. */
typedef RoomView = {
	final phase:RoomPhase;
	final track:Int;

	/** The browser that chooses the track and starts races. */
	final host:String;

	final seats:Array<SeatHolder>;

	/** Every browser in the room, and how many people each brought. */
	final browsers:Array<{session:String, people:Int}>;

	/** A quick match (anyone can be put in it) rather than a room joined by its link. */
	final quick:Bool;

	/** Seconds until a quick match starts by itself, or -1. */
	final startsIn:Float;

	/** The tournament the room is racing, if it was made for one (Tom, 5 Nov). */
	final tournament:Null<shunt.tournament.Tournament.TournamentView>;
}

/** A race begins: the track, the seed, and who sits where (so every browser sets up the very same race and AI drivers). */
typedef RaceStart = {
	final track:Int;
	final seed:Int;
	final seats:Array<SeatHolder>;
}

/** The race as the server has it, with each browser's last input number used, and the input each seat used last. */
typedef Snapshot = {
	final state:RaceState;
	final usedUpTo:haxe.DynamicAccess<Int>;
	final lastInputs:Array<CarInput>;
}
