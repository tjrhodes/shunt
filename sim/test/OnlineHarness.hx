import haxe.Json;
import shunt.ai.AiDriver;
import shunt.ai.DriverCharacter;
import shunt.ai.RacingLine;
import shunt.car.CarInput;
import shunt.online.Messages;
import shunt.online.OnlineTuning;
import shunt.online.Pose;
import shunt.online.Prediction;
import shunt.online.RaceRoom;
import shunt.track.Track;

/** A message on its way, and when it gets there (seconds). */
typedef InFlight = {
	final arrives:Float;
	final deliver:() -> Void;
}

/**
 * A pretend browser for the checks: it predicts the race like a real one,
 * with an AI driver at the wheel of each of its seats (driving the
 * predicted race, as a person would), and notes how far each correction
 * from the server moves its first car.
 */
class PretendBrowser {
	public final session:String;
	public final people:Int;
	public var room:Null<RoomView> = null;
	public var prediction:Null<Prediction> = null;
	public var hands:Array<AiDriver> = [];
	public final corrections:Array<Float> = [];

	/** How far each correction moved the cars of other people in the room (the jumps seen of them). */
	public final othersCorrections:Array<Float> = [];

	/** And of the AI drivers' cars (predicted exactly, so these should be nothing). */
	public final aiCorrections:Array<Float> = [];
	public var lastSnapshot:Null<Snapshot> = null;
	public final waitingToSend:Array<shunt.online.InputQueue.NumberedInputs> = [];

	/** In real life (see `OnlineHarness.realLife`): messages waiting for the next frame, the page's own clock, and when its next frame comes. */
	public final inbox:Array<{type:String, message:Dynamic}> = [];
	public var steps:Null<shunt.FixedSteps> = null;
	public var nextFrameAt = 0.0;

	public function new(session:String, people:Int) {
		this.session = session;
		this.people = people;
	}
}

/**
 * The server's room and some pretend browsers, joined by a pretend network
 * that delays every message by a set time each way (SPEC.md §9). Messages
 * are turned into JSON and back on the way, as the real network does, so
 * nothing is shared by accident. Time moves a tick at a time.
 */
class OnlineHarness {
	public final room:RaceRoom;
	public final browsers:Array<PretendBrowser> = [];
	final oneWaySeconds:Float;
	final inFlight:Array<InFlight> = [];
	final tracks:Array<Track>;
	final lines:Array<RacingLine>;
	public var now(default, null) = 0.0;

	/** What the room wrote to the server's log. */
	public final logged:Array<String> = [];
	var ticksSoFar = 0;

	/**
	 * Up to this much more delay on any message (seconds), at random, as a
	 * real network and real frame times give; messages still arrive in the
	 * order sent (WebSockets keep order).
	 */
	public var jitterSeconds = 0.0;

	/** Whether the people steer like keyboard players: full lock or none, foot flat or off. */
	public var keyboardHands = false;

	var lastArrival = 0.0;

	/**
	 * Real life, for measuring (Tom, 5 Nov: cars jumped in a real race). Off,
	 * the server and every browser move a tick at a time together. On, each
	 * keeps its own clock as the real ones do: browsers draw 60 frames a
	 * second, now and then a slow one (`browserStall`), and only then hear
	 * what has arrived and run the ticks due; the server now and then stalls
	 * too (`serverStall`). A stall happens every `stallEverySeconds`.
	 */
	public var realLife = false;
	public var browserStallSeconds = 0.15;
	public var serverStallSeconds = 0.12;
	public var stallEverySeconds = 2.5;

	/** In real life: whether a browser catches up with only the newest snapshot each frame (or with every one, in turn). */
	public var newestSnapshotOnly = true;

	/** In real life: the most ticks a browser runs in one frame to keep up. */
	public var mostTicksPerFrame = OnlineTuning.mostTicksCaughtUp;

	/** A room (a quick match, or one joined by its link, perhaps for a tournament on the tracks given). */
	public function new(oneWaySeconds:Float, quick:Bool, ?tournamentTracks:Array<Int>, ?firstTrack:Int) {
		this.oneWaySeconds = oneWaySeconds;
		tracks = TestRaces.everyTrackText.map(Track.fromJson);
		lines = tracks.map(track -> new RacingLine(track));
		room = new RaceRoom(TestRaces.everyTrackText, {quick: quick, tournament: tournamentTracks, track: firstTrack}, {toEveryone: toEveryone, log: line -> logged.push(line)});
	}

	/** A browser comes in and asks for seats for its people. */
	public function arrive(session:String, people:Int):PretendBrowser {
		var browser = new PretendBrowser(session, people);
		browsers.push(browser);
		room.arrive(session);
		room.wantSeats(session, {people: people});
		return browser;
	}

	/** Moves time on by a tick: the server, then every browser, then the network. */
	public function tick() {
		now = ++ticksSoFar / Tick.perSecond;
		if (!realLife || !isStalled(0.3, serverStallSeconds)) room.advance(now * 1000);
		for (browser in browsers) realLife ? maybeAFrame(browser) : browserTick(browser);
		deliverWhatHasArrived();
	}

	/** Whether now falls in a stall (of so long, starting so far into each `stallEverySeconds`). */
	function isStalled(startsAt:Float, seconds:Float):Bool {
		var into = (now / stallEverySeconds - Math.floor(now / stallEverySeconds)) * stallEverySeconds;
		return into >= startsAt && into < startsAt + seconds;
	}

	/** In real life: a browser's frame, if one is due (60 a second, but none during a stall): it hears what has come, then runs its ticks. */
	function maybeAFrame(browser:PretendBrowser) {
		if (now < browser.nextFrameAt || isStalled(1.4, browserStallSeconds)) return;
		browser.nextFrameAt = now + 1 / 60;
		var heard = browser.inbox.splice(0, browser.inbox.length);
		var newest = Lambda.fold(heard, (each, last) -> each.type == Messages.snapshot ? each : last, null);
		for (each in heard) if (each.type != Messages.snapshot || !newestSnapshotOnly || each == newest) actOn(browser, each.type, each.message);
		if (browser.steps == null) return;
		for (_ in 0...browser.steps.ticksDue(now * 1000)) browserTick(browser);
	}

	/** Runs ticks until a condition holds, or a number of seconds pass. */
	public function runUntil(done:() -> Bool, mostSeconds:Float) {
		var until = now + mostSeconds;
		while (!done() && now < until) tick();
	}

	/** A browser's tick: its people drive the predicted race, and every other tick (60 a second, a frame) it sends their inputs. */
	function browserTick(browser:PretendBrowser) {
		var prediction = browser.prediction;
		if (prediction == null) return;
		var inputs = [for (index in 0...browser.hands.length) handsOn(browser.hands[index].inputFor(prediction.race, prediction.mySeats()[index]))];
		browser.waitingToSend.push(prediction.stepWith(inputs));
		if (browser.waitingToSend.length < 2) return;
		var batch = Prediction.batchOf(browser.waitingToSend.splice(0, browser.waitingToSend.length));
		send(() -> room.takeInputs(browser.session, copied(batch)));
	}

	/** An AI driver's input as a person would give it: keyboard players press or don't. */
	function handsOn(input:CarInput):CarInput {
		if (!keyboardHands) return input;
		var pressed = (amount:Float) -> amount > 0.5 ? 1.0 : 0.0;
		var steer = Math.abs(input.steer) > 0.3 ? (input.steer > 0 ? 1.0 : -1.0) : 0.0;
		return {throttle: pressed(input.throttle), brake: pressed(input.brake), steer: steer, recover: input.recover};
	}

	function toEveryone(type:String, message:Dynamic) {
		var copy = copied(message);
		for (browser in browsers) send(() -> hear(browser, type, copy));
	}

	/** A browser hears from the server (in real life, at its next frame). */
	function hear(browser:PretendBrowser, type:String, message:Dynamic) {
		if (realLife) browser.inbox.push({type: type, message: message});
		else actOn(browser, type, message);
	}

	function actOn(browser:PretendBrowser, type:String, message:Dynamic) {
		if (type == Messages.room) browser.room = message;
		if (type == Messages.raceStarts) startPredicting(browser, message);
		if (type == Messages.snapshot && browser.prediction != null) catchUp(browser, message);
	}

	function startPredicting(browser:PretendBrowser, start:RaceStart) {
		browser.prediction = new Prediction(tracks[start.track], lines[start.track], start, browser.session);
		browser.hands = [for (seat in browser.prediction.mySeats()) new AiDriver(DriverCharacters.forSeat(start.seed, seat), lines[start.track], seat)];
		browser.waitingToSend.resize(0);
		browser.steps = new shunt.FixedSteps(mostTicksPerFrame);
		browser.steps.ticksDue(now * 1000);
	}

	/** A snapshot arrives: the browser catches up, and notes how far its first car was moved. */
	function catchUp(browser:PretendBrowser, snapshot:Snapshot) {
		var mine = browser.prediction.mySeats();
		browser.lastSnapshot = snapshot;
		var before = Poses.of(browser.prediction.race.state);
		browser.prediction.catchUpWith(snapshot);
		var after = Poses.of(browser.prediction.race.state);
		if (mine.length > 0) browser.corrections.push(before[mine[0]].position.distanceTo(after[mine[0]].position));
		for (seat in 0...after.length) {
			var jump = before[seat].position.distanceTo(after[seat].position);
			if (isSomeoneElses(snapshot, seat, browser)) browser.othersCorrections.push(jump);
			if ((browser.room?.seats[seat]?.owner ?? "") == "") browser.aiCorrections.push(jump);
		}
	}

	/** Whether a seat is driven by a person in another browser. */
	function isSomeoneElses(snapshot:Snapshot, seat:Int, browser:PretendBrowser):Bool {
		var owner = browser.room?.seats[seat]?.owner ?? "";
		return owner != "" && owner != browser.session;
	}

	function send(deliver:() -> Void) {
		lastArrival = Math.max(lastArrival, now + oneWaySeconds + Math.random() * jitterSeconds);
		inFlight.push({arrives: lastArrival, deliver: deliver});
	}

	function deliverWhatHasArrived() {
		while (inFlight.length > 0 && inFlight[0].arrives <= now) inFlight.shift().deliver();
	}

	static function copied<T>(thing:T):T {
		return Json.parse(Json.stringify(thing));
	}
}
