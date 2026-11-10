package online;

import hud.Panels;
import hud.Words;
import input.Controls;
import js.Browser;
import online.Colyseus;
import seats.Lineup;
import shunt.ai.DriverCharacter;
import shunt.ai.RacingLine;
import shunt.car.CarInput;
import shunt.online.InputQueue.NumberedInputs;
import shunt.online.Messages;
import shunt.online.OnlineTuning;
import online.NetReadout.CarKind;
import shunt.online.Pose;
import shunt.online.Prediction;
import shunt.online.Smoothing;
import shunt.race.Race;
import shunt.track.Track;
import shunt.tournament.Tournament;
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
 * where this browser predicts them too (carrying on with their last
 * input), so a bump happens where it is seen; when the server says
 * otherwise, they are eased there as well.
 */
class OnlineRace {
	final around:Surroundings;
	final steps = new FixedSteps(OnlineTuning.mostTicksCaughtUp);
	final waitingToSend:Array<NumberedInputs> = [];
	var room:Null<ColyseusRoom> = null;
	var view:Null<RoomView> = null;
	var prediction:Null<Prediction> = null;
	var gatheringRace:Null<Race> = null;
	var smoothings:Array<Smoothing> = [];
	var posesBefore:Array<Pose> = [];
	var isMenuShowing = false;

	/** In a tournament room, after a race: whether the standings show (rather than the race's results). */
	var isShowingStandings = false;

	/** Whether the host is choosing the room's track on the cards (a stage of its own, off the room panel). */
	var isChoosingTrack = false;

	/** The seed of the race under way (or just finished), or -1 before the first: the AI drivers' kinds come from it. */
	var raceSeed = -1;

	/** When the room last said how long until a quick match starts (seconds on the page's clock), to count down from. */
	var countdownHeardAt = 0.0;

	/** The newest snapshot from the server not yet caught up with (older ones are dropped: each holds the whole race). */
	var newestSnapshot:Null<Snapshot> = null;

	/** Over the race while the connection has dropped and the browser is getting back in. */
	final dropNotice = hiddenNotice(Words.reconnecting);

	/** The close code for leaving the room on purpose (Colyseus's CONSENTED). */
	static inline final consented = 4000;

	/** The `?net` readout, if the address asks for it. */
	final readout:Null<NetReadout> = NetReadout.isWanted() ? new NetReadout() : null;

	public function new(around:Surroundings) {
		this.around = around;
	}

	// ---- Getting in and out ----

	/** Finds or makes the room (a new one starting on the track chosen on the cards), then asks for seats. */
	public function join(how:HowToJoin, chosenTrack:Int) {
		around.panels.showConnecting();
		var client = new ColyseusClient(OnlineServer.address());
		var joining = switch how {
			case QuickMatch: client.joinOrCreate("race", {quick: true, track: chosenTrack});
			case NewRoom: client.create("race", {quick: false, track: chosenTrack});
			case NewTournament(tracks): client.create("race", {quick: false, tournament: tracks});
			case RoomById(id): client.joinById(id);
		}
		joining.then(entered, problem -> around.panels.showCantConnect(whatWentWrong(problem)));
	}

	/** The reason a join failed, in the words of whatever failed (shown small, so it can be passed on to fix it). */
	static function whatWentWrong(problem:Dynamic):String {
		var code = problem?.code != null ? ' (${problem.code})' : "";
		Browser.console.warn("Couldn't join the room:", problem);
		return '${problem?.message ?? problem}$code';
	}

	/** In: listen to the room, then ask for a seat for each person here. */
	function entered(joined:ColyseusRoom) {
		room = joined;
		room.onMessage(Messages.room, heardAboutTheRoom);
		room.onMessage(Messages.raceStarts, heardTheRaceStarts);
		room.onMessage(Messages.snapshot, heardASnapshot);
		room.onMessage(Messages.pong, (sentAt:Float) -> readout?.heardPong(sentAt));
		room.onLeave(leftTheRoom);
		room.onDrop((_, _) -> dropNotice.hidden = false);
		room.onReconnect(() -> dropNotice.hidden = true);
		askForSeats();
	}

	static function hiddenNotice(words:String):js.html.Element {
		var notice = hud.Dom.make("p", "reconnecting", words, Browser.document.body);
		notice.hidden = true;
		return notice;
	}

	/**
	 * Out of the room. Meaning to (Leave), back to the cards. Otherwise the
	 * connection dropped and the browser couldn't get back in (Tom, 10 Nov):
	 * the race stops here, and the room panel says so (with its Leave).
	 */
	function leftTheRoom(code:Int) {
		dropNotice.hidden = true;
		room = null;
		if (code == consented) return around.whenGone();
		prediction = null;
		gatheringRace = null;
		around.show.sound.quieten();
		around.panels.showLostTheRace(code);
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
		countdownHeardAt = secondsNow();
		if (prediction != null && view.phase == Racing) prediction.reseat(view.seats);
		if (view.phase == Gathering) prediction = null;
		if (view.phase == Gathering && !isChoosingTrack) gatherOn(view.track);
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
		forgetTheLastRace(start.seed);
		smoothings = [for (seat in 0...start.seats.length) smoothingFor(seat)];
		posesBefore = Poses.of(prediction.race.state);
		steps.startAfresh();
		around.show.hud.seat(prediction.mySeats());
		around.panels.hideAll();
	}

	/** What was left from the last race (or the room before it): a snapshot still waiting isn't this race's, nor are inputs not yet sent. */
	function forgetTheLastRace(seed:Int) {
		newestSnapshot = null;
		waitingToSend.resize(0);
		isShowingStandings = false;
		gatheringRace = null;
		raceSeed = seed;
	}

	/** Our cars' corrections are eased quickly; other people's (guessed from what they last pressed, so corrected more) more gently. */
	function smoothingFor(seat:Int):Smoothing {
		var isOurs = prediction.mySeats().contains(seat);
		return new Smoothing(isOurs ? OnlineTuning.correctionEasedOverSeconds : OnlineTuning.othersCorrectionEasedOverSeconds);
	}

	/**
	 * A snapshot: kept, to catch up with on the next frame. Several can arrive
	 * between frames, and catching up with each one costs a replay of every
	 * tick we're ahead; when a page fell behind, that cost grew until it
	 * never caught up again (Tom, 5 Nov: a race with his son lagged and the
	 * cars jumped). Only the newest is needed: it holds the whole race.
	 */
	function heardASnapshot(snapshot:Snapshot) {
		newestSnapshot = snapshot;
		readout?.heardASnapshot();
	}

	/**
	 * The server's race, a little in the past: catch up from it, and ease in
	 * any jump in the cars. Where each car was a tick ago moves with it, so
	 * drawing carries on smoothly between ticks (Tom, 5 Nov: it was reset to
	 * where the car is now, nudging every car forward 30 times a second).
	 */
	function catchUpWithTheNewest() {
		var snapshot = newestSnapshot;
		newestSnapshot = null;
		if (prediction == null || snapshot == null) return;
		var before = Poses.of(prediction.race.state);
		prediction.catchUpWith(snapshot);
		var after = Poses.of(prediction.race.state);
		for (seat in 0...after.length) {
			smoothings[seat].corrected(before[seat], after[seat]);
			posesBefore[seat] = Poses.shifted(posesBefore[seat], before[seat], after[seat]);
			readout?.corrected(kindOf(seat), before[seat].position.distanceTo(after[seat].position));
		}
		if (snapshot.state.phase == Finished) showThePanel();
	}

	/** For the readout: whose car a seat is. */
	function kindOf(seat:Int):CarKind {
		if (isOurs(seat)) return Ours;
		return view?.seats[seat]?.owner != "" ? SomeoneElses : AnAi;
	}

	// ---- Every frame ----

	/** Runs the ticks due (racing) or watches for people taking seats (between races), then draws. */
	public function frame(now:Float, secondsSinceLastFrame:Float) {
		catchUpWithTheNewest();
		if (isRacing()) {
			for (_ in 0...steps.ticksDue(now)) tick();
			sendWhatIsWaiting();
			around.show.animate(secondsSinceLastFrame);
		} else if (view != null && view.phase != Racing && around.lineup.people() != peopleAsked() && whoIsHere()) askForSeats();
		if (view != null && view.startsIn >= 0 && !isRacing()) around.panels.showCountdown(view.startsIn - (secondsNow() - countdownHeardAt));
		draw(secondsSinceLastFrame);
		measure(now);
	}

	/** With `?net`: a ping now and then, and the readout kept up to date. */
	function measure(now:Float) {
		if (readout == null || room == null) return;
		if (readout.wantsAPing(now)) room.send(Messages.ping, Browser.window.performance.now());
		readout.frame(now, prediction?.ticksAhead() ?? 0);
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

	/** Every car part way into the next tick, with any correction eased in; the grid between races. */
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
		return smoothings[seat].shown(Poses.between(posesBefore[seat], now[seat], share), secondsSinceLastFrame);
	}

	// ---- What shows ----

	/** The panel for where the room has got to: the room before a race, the results after; none while racing (unless the menu is open). */
	function showThePanel() {
		if (view == null || isMenuShowing) return;
		if (isChoosingTrack && view.phase == Gathering && isHost()) return around.panels.markTrack(view.track);
		isChoosingTrack = false;
		if (view.phase == Gathering || (view.phase == Racing && prediction == null)) showTheRoom();
		else if (view.phase == Results && prediction != null) showResultsOrStandings();
		else if (view.phase == Results) showTheRoom();
	}

	/** After a race: its results, or in a tournament (once asked for) the standings. */
	function showResultsOrStandings() {
		if (isShowingStandings) around.panels.showStandings(Tournament.fromView(view.tournament), drivers(), {isHost: isHost()});
		else around.panels.showResults(prediction.race, drivers(), {isHost: isHost()}, view.tournament != null);
	}

	function showTheRoom() {
		var link = view.quick ? null : OnlineServer.linkTo(room.roomId);
		around.panels.showRoom(view, seatLooks(), isHost(), link);
	}

	/** Each seat's card: ours, someone else's, or an AI driver's. */
	function seatLooks():Array<SeatLook> {
		return [for (seat in 0...view.seats.length) {
			var holder = view.seats[seat];
			{who: drivers().nameOf(seat), how: holder.owner == "" ? Words.freeSeat : "", isAPerson: holder.owner != "", isOurs: holder.owner == room.sessionId};
		}];
	}

	/** Names for every seat: "You" if one of us races alone, "Player 3" for any other person, an AI car's number. */
	function drivers():Drivers {
		var oursCount = Lambda.count(view.seats, holder -> holder.owner == room.sessionId);
		return {
			nameOf: seat -> Words.driverName(seat, aiNameOf(seat), view.seats[seat].owner != "", isOurs(seat) && oursCount == 1),
			isOurs: isOurs
		};
	}

	/** An AI seat's name: its kind once a race has started (its drivers come from the race's seed), plain "AI" before. */
	function aiNameOf(seat:Int):String {
		return raceSeed < 0 ? Words.aiDriver : Words.aiKinds[DriverCharacters.kindOf(raceSeed, seat)];
	}

	/** The pause key online: the race can't stop, but a menu opens (sound, leave) and closes again. */
	public function pressPause(soundIsOn:Bool) {
		isMenuShowing = !isMenuShowing;
		if (isMenuShowing) around.panels.showPause(soundIsOn, Words.leave, false);
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

	/** The host's "Change track": the track cards, as on this computer; each card chosen is the room's track at once. */
	public function browseTracks() {
		if (view == null || !isHost()) return;
		isChoosingTrack = true;
		around.panels.showTracks(view.track, Words.useThisTrack);
	}

	/** A card pressed: the first press chooses it, a second on the chosen one goes back to the room. */
	public function pickCard(track:Int) {
		if (track == view.track) doneWithTracks();
		else chooseTrack(track);
	}

	/** A push or swipe while the cards show: that many cards along. */
	public function nextCard(cards:Int) {
		var count = around.tracks.length;
		if (isChoosingTrack) chooseTrack(((view.track + cards) % count + count) % count);
	}

	/** Back from the cards to the room. */
	public function doneWithTracks() {
		isChoosingTrack = false;
		if (view.phase == Gathering) gatherOn(view.track);
		showThePanel();
	}

	/** While the host turns the ring of cards, the track behind follows it (the room's own track may already be further on). */
	public function showTrackBehind(track:Int) {
		if (isChoosingTrack) gatherOn(track);
	}

	/** The results' go button: in a tournament, on to the standings (for everyone); else the host starts the next race. */
	public function raceAgain() {
		if (view?.tournament == null || prediction == null) return startRace();
		isShowingStandings = true;
		showThePanel();
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
