package shunt.online;

import shunt.ai.AiDriver;
import shunt.ai.RacingLine;
import shunt.car.CarInput;
import shunt.online.Messages;
import shunt.race.Race;
import shunt.track.Track;
import shunt.tournament.Tournament;

/** How the room speaks to the browsers in it: the server gives it this. */
typedef Outbox = {
	/** Sends a message to every browser in the room. */
	final toEveryone:(type:String, message:Dynamic) -> Void;
}

/**
 * The server's side of one online room (SPEC.md §9): who is in it, the
 * track, and the race itself, run at the same 120 ticks a second as in the
 * browser, with people's inputs from the network and AI drivers in the
 * empty seats. The server's own code only passes messages in and out; every
 * decision is made here, in the same Haxe as the rest of the game.
 *
 * A room made for friends can run a tournament (Tom, 5 Nov): its races go
 * in order on the tournament's tracks, each finish is scored, and the
 * standings go to everyone with the rest of the room.
 */
@:expose("RaceRoom")
class RaceRoom {
	final tracks:Array<Track>;
	final racingLines:Array<RacingLine>;
	final quick:Bool;
	final outbox:Outbox;
	final roomSeats = new RoomSeats();
	final queues = new Map<String, InputQueue>();
	final steps = new FixedSteps();
	var phase = Gathering;
	var track = 0;
	var race:Null<Race> = null;
	var drivers:Array<Null<AiDriver>> = [];
	var lastInputs:Array<CarInput> = [];

	/** The race's seed: its AI drivers are made from it, here and in every browser. */
	var seed = 0;
	var startsIn = -1.0;

	/** The tournament this room races, if it was made for one. */
	final tournament:Null<Tournament>;

	/**
	 * A room for tracks given as the text of their JSON files, made as asked: a
	 * quick match or a room joined by its link, starting on the track asked
	 * for. A room joined by its link may be for a tournament on the tracks
	 * given (by number, in order), and starts on its first.
	 */
	public function new(trackTexts:Array<String>, asked:Null<RoomAsked>, outbox:Outbox) {
		tracks = trackTexts.map(Track.fromJson);
		racingLines = tracks.map(track -> new RacingLine(track));
		quick = asked?.quick == true;
		this.outbox = outbox;
		var isATournament = !quick && Tournament.isATournament(asked?.tournament, tracks.length);
		tournament = isATournament ? Tournament.on(asked.tournament, tracks.length, OnlineTuning.seats, Std.random) : null;
		track = tournament != null ? tournament.nextTrack() : isAKnownTrack(asked?.track) ? asked.track : 0;
	}

	/** Whether a browser named one of the room's tracks. */
	function isAKnownTrack(track:Dynamic):Bool {
		return Std.isOfType(track, Int) && track >= 0 && track < tracks.length;
	}

	// ---- Messages from browsers ----

	/** A browser came in: it watches until it asks for seats. */
	public function arrive(session:String) {
		roomSeats.arrive(session);
		queues.set(session, new InputQueue());
		tellEveryoneAboutTheRoom();
	}

	/** A browser says how many people it brings; between races they are seated at once. */
	public function wantSeats(session:String, wanted:SeatsWanted) {
		roomSeats.want(session, Std.isOfType(wanted?.people, Int) ? wanted.people : 0);
		if (phase != Racing) roomSeats.seatEveryone();
		tellEveryoneAboutTheRoom();
	}

	/** A browser left: AI drivers take its seats (mid-race, at once). */
	public function depart(session:String) {
		roomSeats.depart(session);
		queues.remove(session);
		if (phase == Racing) handEmptySeatsToAi();
		else roomSeats.seatEveryone();
		tellEveryoneAboutTheRoom();
	}

	/** The host picks a track, between races. */
	public function chooseTrack(session:String, choice:TrackChoice) {
		if (session != roomSeats.host() || phase == Racing || !isAKnownTrack(choice?.track) || tournament != null) return;
		track = choice.track;
		tellEveryoneAboutTheRoom();
	}

	/** The host starts the race, between races. */
	public function startRace(session:String) {
		if (session == roomSeats.host() && phase != Racing) begin();
	}

	public function takeInputs(session:String, batch:InputBatch) {
		var queue = queues.get(session);
		if (queue != null) queue.add(batch);
	}

	// ---- Time ----

	/** Runs the ticks that are due by now (milliseconds), and counts down a quick match's start. */
	public function advance(nowMilliseconds:Float) {
		var ticks = steps.ticksDue(nowMilliseconds);
		if (phase == Racing) for (_ in 0...ticks) tick();
		else countDownAQuickMatch(ticks * Tick.seconds);
	}

	/** One tick of the race: everyone's input, a step, and now and then a snapshot for the browsers. */
	function tick() {
		lastInputs = everyonesInput();
		race.step(lastInputs);
		var isOver = race.state.phase == Finished;
		if (race.state.tick % OnlineTuning.ticksBetweenSnapshots == 0 || isOver) sendSnapshot();
		if (isOver) finish();
	}

	/** Each seat's input: its AI driver's, or the next from the queue of the browser that holds it. */
	function everyonesInput():Array<CarInput> {
		var thisTicks = [for (session => queue in queues) session => queue.next()];
		return [for (seat in 0...roomSeats.seats.length) inputFor(seat, thisTicks)];
	}

	function inputFor(seat:Int, thisTicks:Map<String, Array<CarInput>>):CarInput {
		var driver = drivers[seat];
		if (driver != null) return driver.inputFor(race, seat);
		var holder = roomSeats.seats[seat];
		return InputQueue.personsInput(thisTicks.get(holder.owner) ?? [], holder.person);
	}

	// ---- Races ----

	/** A new race: everyone seated, a fresh seed, AI drivers in the empty seats; every browser is told how to set up the same race. */
	function begin() {
		roomSeats.seatEveryone();
		nextInTheTournament();
		seed = tournament != null ? tournament.seedForARace() : Std.random(1000000000) + 1;
		race = new Race(tracks[track], {cars: OnlineTuning.seats, laps: tracks[track].laps, seed: seed});
		drivers = SeatDrivers.forSeats(roomSeats.seats, seed, racingLines[track]);
		for (session in queues.keys()) queues.set(session, new InputQueue());
		phase = Racing;
		startsIn = -1;
		steps.startAfresh();
		outbox.toEveryone(Messages.raceStarts, ({track: track, seed: seed, seats: roomSeats.seats.copy()} : RaceStart));
		tellEveryoneAboutTheRoom();
	}

	/** The race is over: in a tournament it scores; its results show until the next one. */
	function finish() {
		phase = Results;
		if (tournament != null) tournament.score(race.state.order);
		tellEveryoneAboutTheRoom();
	}

	/** In a tournament, the next race is on its next track; once it's over, the same tracks again from no points. */
	function nextInTheTournament() {
		if (tournament == null) return;
		if (tournament.isOver()) tournament.again();
		track = tournament.nextTrack();
	}

	/** Seats whose people have gone get AI drivers, carrying on from where the car is. */
	function handEmptySeatsToAi() {
		var everyAiDriver = SeatDrivers.forSeats(roomSeats.seats, seed, racingLines[track]);
		for (seat in 0...drivers.length) if (drivers[seat] == null) drivers[seat] = everyAiDriver[seat];
	}

	/** In a quick match, once two people are in, the race starts by itself after a while. */
	function countDownAQuickMatch(seconds:Float) {
		var wasCounting = startsIn >= 0;
		var enoughPeople = quick && roomSeats.peopleHere() >= 2;
		startsIn = !enoughPeople ? -1 : (wasCounting ? startsIn - seconds : OnlineTuning.quickMatchStartsAfterSeconds);
		if (enoughPeople && startsIn <= 0) begin();
		else if (wasCounting != (startsIn >= 0)) tellEveryoneAboutTheRoom();
	}

	// ---- Telling the browsers ----

	function sendSnapshot() {
		var usedUpTo = new haxe.DynamicAccess<Int>();
		for (session => queue in queues) usedUpTo.set(session, queue.usedUpTo);
		outbox.toEveryone(Messages.snapshot, ({state: race.state, usedUpTo: usedUpTo, lastInputs: lastInputs} : Snapshot));
	}

	function tellEveryoneAboutTheRoom() {
		outbox.toEveryone(Messages.room, view());
	}

	/** The room as everyone sees it. */
	public function view():RoomView {
		return {
			phase: phase,
			track: track,
			host: roomSeats.host(),
			seats: roomSeats.seats.copy(),
			browsers: [for (browser in roomSeats.browsers) {session: browser.session, people: browser.people}],
			quick: quick,
			startsIn: startsIn,
			tournament: tournament?.view()
		};
	}
}
