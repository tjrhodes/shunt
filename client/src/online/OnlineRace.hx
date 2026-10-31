package online;

import hud.Panels;
import hud.Words;
import input.Controls;
import js.Browser;
import online.Colyseus;
import seats.Lineup;
import shunt.ai.RacingLine;
import shunt.car.CarInput;
import shunt.online.InputQueue.NumberedInputs;
import shunt.online.Messages;
import shunt.online.Pose;
import shunt.online.Prediction;
import shunt.online.ShownBehind;
import shunt.online.Smoothing;
import shunt.race.Race;
import shunt.track.Track;
import view.Paint;

/** What an online race needs from the game around it. */
typedef Surroundings = {
	final tracks:Array<Track>;
	final racingLines:Array<RacingLine>;
	final show:Show;
	final panels:Panels;
	final controls:Controls;
	final lineup:Lineup;

	/** Called once the room is left, however that happened. */
	final whenGone:() -> Void;
}

/**
 * Racing online, in the browser (SPEC.md §9): joining a room, asking for a
 * seat for each person here, and racing the server's race. This browser's
 * cars are predicted (`Prediction`), so they answer at once; corrections
 * from the server are eased in (`Smoothing`); other people's cars are drawn
 * a moment in the past, smoothly between snapshots (`ShownBehind`).
 */
class OnlineRace {
	final around:Surroundings;
	final steps = new FixedSteps();
	final behind = new ShownBehind();
	final waitingToSend:Array<NumberedInputs> = [];
	var room:Null<ColyseusRoom> = null;
	var view:Null<RoomView> = null;
	var prediction:Null<Prediction> = null;
	var gatheringRace:Null<Race> = null;
	var smoothings:Array<Smoothing> = [];
	var posesBefore:Array<Pose> = [];
	var isMenuShowing = false;

	public function new(around:Surroundings) {
		this.around = around;
	}

	// ---- Getting in and out ----

	/** Finds or makes the room, then asks for seats. */
	public function join(how:HowToJoin) {
		around.panels.showConnecting();
		var client = new ColyseusClient(OnlineServer.address());
		var joining = switch how {
			case QuickMatch: client.joinOrCreate("race", {quick: true});
			case NewRoom: client.create("race", {quick: false});
			case RoomById(id): client.joinById(id);
		}
		joining.then(entered, _ -> around.panels.showCantConnect());
	}

	/** In: listen to the room, then ask for a seat for each person here. */
	function entered(joined:ColyseusRoom) {
		room = joined;
		room.onMessage(Messages.room, heardAboutTheRoom);
		room.onMessage(Messages.raceStarts, heardTheRaceStarts);
		room.onMessage(Messages.snapshot, heardASnapshot);
		room.onLeave(_ -> around.whenGone());
		askForSeats();
	}

	function askForSeats() {
		room.send(Messages.takeSeats, ({people: around.lineup.people()} : SeatsWanted));
	}

	/** Leaves the room (or stops trying to get in). */
	public function leave() {
		if (room != null) room.leave(true);
		else around.whenGone();
	}

	// ---- Hearing from the server ----

	function heardAboutTheRoom(heard:RoomView) {
		view = heard;
		if (prediction != null && view.phase == Racing) prediction.reseat(view.seats);
		if (view.phase == Gathering) prediction = null;
		if (view.phase == Gathering) gatherOn(view.track);
		showThePanel();
	}

	/** Before a race: the track chosen, with the cars on its grid. */
	function gatherOn(track:Int) {
		if (gatheringRace != null && gatheringRace.track == around.tracks[track]) return;
		around.show.showTrack(around.tracks[track]);
		gatheringRace = new Race(around.tracks[track], {cars: Paint.liveries.length, laps: around.tracks[track].laps, seed: 1});
		around.show.freshRace();
	}

	/** A race begins: this browser sets up the very same race, and drives its seats in it. */
	function heardTheRaceStarts(start:RaceStart) {
		var track = around.tracks[start.track];
		around.show.showTrack(track);
		around.show.freshRace();
		prediction = new Prediction(track, around.racingLines[start.track], start, room.sessionId);
		gatheringRace = null;
		smoothings = [for (_ in start.seats) new Smoothing()];
		posesBefore = Poses.of(prediction.race.state);
		behind.clear();
		waitingToSend.resize(0);
		steps.startAfresh();
		around.show.hud.seat(prediction.mySeats());
		around.panels.hideAll();
	}

	/** The server's race, a little in the past: catch up from it, ease in any jump in our cars, and keep it for drawing the others. */
	function heardASnapshot(snapshot:Snapshot) {
		if (prediction == null) return;
		var before = Poses.of(prediction.race.state);
		prediction.catchUpWith(snapshot);
		var after = Poses.of(prediction.race.state);
		for (seat in prediction.mySeats()) smoothings[seat].corrected(before[seat], after[seat]);
		posesBefore = after;
		behind.arrived(secondsNow(), Poses.of(snapshot.state));
		if (snapshot.state.phase == Finished) showThePanel();
	}

	// ---- Every frame ----

	/** Runs the ticks due (racing) or watches for people taking seats (between races), then draws. */
	public function frame(now:Float, secondsSinceLastFrame:Float) {
		if (isRacing()) {
			for (_ in 0...steps.ticksDue(now)) tick();
			sendWhatIsWaiting();
			around.show.animate(secondsSinceLastFrame);
		} else if (view != null && view.phase != Racing && around.lineup.people() != peopleAsked() && whoIsHere()) askForSeats();
		draw(secondsSinceLastFrame);
	}

	/** Between races (or not yet in): the people here can still take or give back seats. */
	public function isBetweenRaces():Bool {
		return view == null || view.phase != Racing;
	}

	function isRacing():Bool {
		return prediction != null && prediction.race.state.phase != Finished;
	}

	/** One tick ahead: our people's inputs, the predicted race, and what it left behind. */
	function tick() {
		posesBefore = Poses.of(prediction.race.state);
		waitingToSend.push(prediction.stepWith(ourInputs()));
		around.show.afterTick(prediction.race);
	}

	/** Each of our seats' input, from the controllers of the person here in that place. */
	function ourInputs():Array<CarInput> {
		var controls = around.controls;
		return [for (seat in around.lineup.humanSeats()) controls.carInputFrom(around.lineup.controllersFor(seat, controls.every()))];
	}

	/** Our inputs since the last frame, in one message. */
	function sendWhatIsWaiting() {
		if (waitingToSend.length == 0) return;
		room.send(Messages.inputs, Prediction.batchOf(waitingToSend.splice(0, waitingToSend.length)));
	}

	/** Our cars part way into the next tick, eased; everyone else's a moment in the past; the grid between races. */
	function draw(secondsSinceLastFrame:Float) {
		var race = prediction?.race ?? gatheringRace;
		if (race == null) return;
		var now = Poses.of(race.state);
		var share = isRacing() ? steps.shareIntoTheNextTick() : 1;
		var poses = [for (seat in 0...now.length) poseToShow(seat, now, share, secondsSinceLastFrame)];
		around.show.draw(race, poses, isRacing());
	}

	function poseToShow(seat:Int, now:Array<Pose>, share:Float, secondsSinceLastFrame:Float):Pose {
		if (prediction == null) return now[seat];
		if (isOurs(seat)) return smoothings[seat].shown(Poses.between(posesBefore[seat], now[seat], share), secondsSinceLastFrame);
		return behind.poseOf(seat, secondsNow()) ?? now[seat];
	}

	// ---- What shows ----

	/** The panel for where the room has got to: the room before a race, the results after; none while racing (unless the menu is open). */
	function showThePanel() {
		if (view == null || isMenuShowing) return;
		if (view.phase == Gathering || (view.phase == Racing && prediction == null)) showTheRoom();
		else if (view.phase == Results && prediction != null) around.panels.showResults(prediction.race, drivers(), {isHost: isHost()});
		else if (view.phase == Results) showTheRoom();
	}

	function showTheRoom() {
		var link = view.quick ? null : OnlineServer.linkTo(room.roomId);
		around.panels.showRoom(view, seatLooks(), isHost(), link);
	}

	/** Each seat's card: ours, someone else's, or an AI driver's. */
	function seatLooks():Array<SeatLook> {
		return [for (seat in 0...view.seats.length) {
			var holder = view.seats[seat];
			{who: drivers().nameOf(seat), how: holder.owner == "" ? Words.aiDriver : "", isAPerson: holder.owner != "", isOurs: holder.owner == room.sessionId};
		}];
	}

	/** Names for every seat: "You" if one of us races alone, "Player 3" for any other person, an AI car's number. */
	function drivers():Drivers {
		var oursCount = Lambda.count(view.seats, holder -> holder.owner == room.sessionId);
		return {
			nameOf: seat -> Words.driverName(seat, Paint.liveries[seat].number, view.seats[seat].owner != "", isOurs(seat) && oursCount == 1),
			isOurs: isOurs
		};
	}

	/** The pause key online: the race can't stop, but a menu opens (sound, leave) and closes again. */
	public function pressPause(soundIsOn:Bool) {
		isMenuShowing = !isMenuShowing;
		if (isMenuShowing) around.panels.showPause(true, soundIsOn);
		else if (isRacing()) around.panels.hideAll();
		else showThePanel();
	}

	public function closeMenu() {
		if (isMenuShowing) pressPause(false);
	}

	// ---- Asking the room ----

	public function chooseTrack(track:Int) {
		if (room != null) room.send(Messages.chooseTrack, ({track: track} : TrackChoice));
	}

	public function startRace() {
		if (room != null) room.send(Messages.startRace);
	}

	// ---- Who's who ----

	/** Whether one of the people here drives a seat. */
	public function isOurs(seat:Int):Bool {
		return view != null && room != null && view.seats[seat].owner == room.sessionId;
	}

	function isHost():Bool {
		return view != null && room != null && view.host == room.sessionId;
	}

	/** Whether the room knows about this browser yet. */
	function whoIsHere():Bool {
		return room != null && Lambda.exists(view.browsers, browser -> browser.session == room.sessionId);
	}

	/** How many people the room thinks this browser brings. */
	function peopleAsked():Int {
		return Lambda.find(view.browsers, browser -> browser.session == room.sessionId)?.people ?? 0;
	}

	static function secondsNow():Float {
		return Browser.window.performance.now() / 1000;
	}
}
