import haxe.Json;
import shunt.ai.AiDriver;
import shunt.ai.DriverCharacter;
import shunt.ai.RacingLine;
import shunt.online.Messages;
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
	public var lastSnapshot:Null<Snapshot> = null;
	public final waitingToSend:Array<shunt.online.InputQueue.NumberedInputs> = [];

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

	public function new(oneWaySeconds:Float, quick:Bool) {
		this.oneWaySeconds = oneWaySeconds;
		tracks = TestRaces.everyTrackText.map(Track.fromJson);
		lines = tracks.map(track -> new RacingLine(track));
		room = new RaceRoom(TestRaces.everyTrackText, quick, {toEveryone: toEveryone});
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
		now += Tick.seconds;
		room.advance(now * 1000);
		for (browser in browsers) browserTick(browser);
		deliverWhatHasArrived();
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
		var inputs = [for (index in 0...browser.hands.length) browser.hands[index].inputFor(prediction.race, prediction.mySeats()[index])];
		browser.waitingToSend.push(prediction.stepWith(inputs));
		if (browser.waitingToSend.length < 2) return;
		var batch = Prediction.batchOf(browser.waitingToSend.splice(0, browser.waitingToSend.length));
		send(() -> room.takeInputs(browser.session, copied(batch)));
	}

	function toEveryone(type:String, message:Dynamic) {
		var copy = copied(message);
		for (browser in browsers) send(() -> hear(browser, type, copy));
	}

	/** A browser hears from the server. */
	function hear(browser:PretendBrowser, type:String, message:Dynamic) {
		if (type == Messages.room) browser.room = message;
		if (type == Messages.raceStarts) startPredicting(browser, message);
		if (type == Messages.snapshot && browser.prediction != null) catchUp(browser, message);
	}

	function startPredicting(browser:PretendBrowser, start:RaceStart) {
		browser.prediction = new Prediction(tracks[start.track], lines[start.track], start, browser.session);
		browser.hands = [for (seat in browser.prediction.mySeats()) new AiDriver(DriverCharacters.forSeat(start.seed, seat), lines[start.track], seat)];
		browser.waitingToSend.resize(0);
	}

	/** A snapshot arrives: the browser catches up, and notes how far its first car was moved. */
	function catchUp(browser:PretendBrowser, snapshot:Snapshot) {
		var mine = browser.prediction.mySeats();
		browser.lastSnapshot = snapshot;
		var before = mine.length > 0 ? Poses.of(browser.prediction.race.state)[mine[0]] : null;
		browser.prediction.catchUpWith(snapshot);
		if (before != null) browser.corrections.push(before.position.distanceTo(Poses.of(browser.prediction.race.state)[mine[0]].position));
	}

	function send(deliver:() -> Void) {
		inFlight.push({arrives: now + oneWaySeconds, deliver: deliver});
	}

	function deliverWhatHasArrived() {
		while (inFlight.length > 0 && inFlight[0].arrives <= now) inFlight.shift().deliver();
	}

	static function copied<T>(thing:T):T {
		return Json.parse(Json.stringify(thing));
	}
}
