import hud.Panels;
import hud.Words;
import input.Controls;
import js.Browser;
import online.HowToJoin;
import online.OnlineRace;
import online.OnlineServer;
import seats.Lineup;
import shunt.ai.AiDriver;
import shunt.ai.DriverCharacter;
import shunt.ai.RacingLine;
import shunt.car.CarInput;
import shunt.online.Pose;
import shunt.race.Race;
import shunt.track.Track;
import view.Paint;

/** What the game is doing. */
enum GameMode {
	/** The first stage of starting: browsing the track cards. */
	ChoosingTrack;

	/** The second: the drivers, seat by seat. */
	ChoosingDrivers;

	Racing;
	Paused;
	RaceOver;

	/** In an online room: `OnlineRace` runs things until it is left. */
	Online;
}

/** The parts of the page the game draws into. */
typedef PageParts = {
	final stage:js.html.Element;
	final hud:js.html.Element;
	final panels:js.html.Element;
	final brakePad:js.html.Element;
	final pauseButton:js.html.Element;
}

/**
 * The game in the browser (SPEC.md §1, §9). On this computer: one race at
 * a time on the track chosen, people in the seats they took (or one person
 * alone) and AI drivers in the rest, drawn every frame between the last two
 * ticks. Online, `OnlineRace` takes over until the room is left. Everything
 * about a race itself is in the shared simulation; this only feeds it
 * inputs and shows what it does.
 */
class Game {
	final tracks:Array<Track>;
	final racingLines:Array<RacingLine>;
	final show:Show;
	final panels:Panels;
	final controls:Controls;
	final lineup = new Lineup(Paint.liveries.length);
	final steps = new FixedSteps();
	var race:Race;

	/** The AI driver in each seat, or nothing where a person drives. */
	var drivers:Array<Null<AiDriver>>;
	var posesBefore:Array<Pose>;
	var mode = ChoosingTrack;

	/** The seed of the race lined up: its AI drivers (and so their kinds, on the seat cards) come from it. */
	var seed = 1;
	var chosenTrack = 0;
	var lastFrameTime = -1.0;
	var online:Null<OnlineRace> = null;

	public function new(tracks:Array<Track>, page:PageParts) {
		this.tracks = tracks;
		racingLines = tracks.map(track -> new RacingLine(track));
		show = new Show(page.stage, page.hud, isOneOfOurs);
		panels = new Panels(page.panels, tracks, panelActions());
		controls = new Controls(page.stage, page.brakePad, page.pauseButton);
		previewTrack(0);
		showTrackCards();
		OnlineServer.lookForOne().then(isThere -> if (isThere) onlineIsHere());
		Browser.window.requestAnimationFrame(frame);
	}

	/** Every button does the same thing on this computer and online, where it means asking the room. */
	function panelActions():PanelActions {
		return {
			chooseTrack: pickCard, moveAlongTheCards: moveAlongTheCards,
			raceHere: () -> mode == Online ? online.doneWithTracks() : toDrivers(),
			start: () -> mode == Online ? online.startRace() : startRacing(),
			resume: () -> mode == Online ? online.closeMenu() : startRacing(),
			toggleSound: toggleSound,
			raceAgain: () -> mode == Online ? online.startRace() : raceAgain(),
			changeTrack: () -> mode == Online ? online.browseTracks() : showTrackCards(),
			goOnline: goOnline,
			joinFriends: () -> goOnline(RoomById(OnlineServer.invitation())),
			raceAlone: forgetTheInvitation,
			leave: () -> if (online != null) online.leave()
		};
	}

	/** Whether a person here drives a seat (online: one of this browser's seats). */
	function isOneOfOurs(seat:Int):Bool {
		return mode == Online ? online.isOurs(seat) : lineup.isHuman(seat);
	}

	// ---- On this computer ----

	/** The first stage of starting: the track cards. */
	function showTrackCards() {
		mode = ChoosingTrack;
		panels.showTracks(chosenTrack);
	}

	/** A track chosen on the cards: shown behind them, with the cars on its grid. */
	function previewTrack(index:Int) {
		chosenTrack = (index % tracks.length + tracks.length) % tracks.length;
		show.showTrack(tracks[chosenTrack]);
		lineUpANewRace();
		panels.markTrack(chosenTrack);
	}

	/** A card pressed: the first press chooses it, a second press on the chosen one goes on to the drivers (online, `OnlineRace` decides). */
	function pickCard(index:Int) {
		if (mode == Online) online.pickCard(index);
		else if (index == chosenTrack) toDrivers();
		else previewTrack(index);
	}

	/** The second stage: the drivers, for a race on the chosen track. */
	function toDrivers() {
		mode = ChoosingDrivers;
		panels.showDrivers(chosenTrack, seatLooks());
	}

	/** On the track cards, a push left or right on any controller (keys, stick) moves to the next card. */
	function browseTheCards() {
		var push = controls.sidewaysJustPushed();
		if (push != 0) moveAlongTheCards(push);
	}

	/** Some cards along (from a push, or a swipe): the next track here, or online the room's next. */
	function moveAlongTheCards(cards:Int) {
		if (mode == Online) online.nextCard(cards);
		else previewTrack(chosenTrack + cards);
	}

	/** One frame: the ticks due and the sparks and smoke moved on (while racing), the presses that happen once, and drawing. */
	function frame(now:Float) {
		var secondsSinceLastFrame = lastFrameTime < 0 ? 0 : Math.min(0.1, (now - lastFrameTime) / 1000);
		lastFrameTime = now;
		if (panels.isShowingTheTracks()) browseTheCards();
		panels.animate(secondsSinceLastFrame);
		if (mode == ChoosingDrivers || (mode == Online && online.isBetweenRaces())) takeSeats();
		if (mode == Online) online.frame(now, secondsSinceLastFrame);
		else frameOnThisComputer(now, secondsSinceLastFrame);
		if (controls.pauseWasJustPressed()) pressPause();
		if (controls.muteWasJustPressed()) toggleSound();
		if (controls.confirmWasJustPressed()) pressYes();
		Browser.window.requestAnimationFrame(frame);
	}

	function frameOnThisComputer(now:Float, secondsSinceLastFrame:Float) {
		if (mode == Racing) {
			for (_ in 0...steps.ticksDue(now)) oneTick();
			show.animate(secondsSinceLastFrame);
			if (race.state.phase == Finished) finished();
		}
		showEverything();
	}

	/** Remembers where every car is, moves the race on a tick, and shows what it left behind. */
	function oneTick() {
		posesBefore = Poses.of(race.state);
		race.step([for (seat in 0...race.state.racers.length) inputFor(seat)]);
		show.afterTick(race);
	}

	/** A seat's input: from its person's controllers, or from its AI driver. */
	function inputFor(seat:Int):CarInput {
		var driver = drivers[seat];
		return driver != null ? driver.inputFor(race, seat) : controls.carInputFrom(lineup.controllersFor(seat, controls.every()));
	}

	function finished() {
		mode = RaceOver;
		show.sound.rest();
		var isAlone = lineup.people() == 1;
		panels.showResults(race, {nameOf: seat -> Words.driverName(seat, Words.aiKinds[DriverCharacters.kindOf(seed, seat)], lineup.isHuman(seat), isAlone), isOurs: lineup.isHuman});
	}

	/** Every car drawn part way between its last two ticks. */
	function showEverything() {
		var share = mode == Racing ? steps.shareIntoTheNextTick() : 1;
		var posesNow = Poses.of(race.state);
		show.draw(race, [for (seat in 0...posesNow.length) Poses.between(posesBefore[seat], posesNow[seat], share)], mode == Racing);
	}

	/** A fresh race on the chosen track, on a new seed, with new AI drivers, lights red. */
	function lineUpANewRace() {
		seed = Std.random(1000000000) + 1;
		var track = tracks[chosenTrack];
		race = new Race(track, {cars: Paint.liveries.length, laps: track.laps, seed: seed});
		drivers = [for (seat in 0...race.state.racers.length) lineup.isHuman(seat) ? null : new AiDriver(DriverCharacters.forSeat(seed, seat), racingLines[chosenTrack], seat)];
		show.hud.seat(lineup.humanSeats());
		posesBefore = Poses.of(race.state);
		show.freshRace();
	}

	// ---- Seats ----

	/** Between races, a press of go on a controller takes a seat here and a press of brake gives it back. */
	function takeSeats() {
		var joined = Lambda.count(controls.throttleJustPressedOn(), lineup.join) > 0;
		var left = Lambda.count(controls.brakeJustPressedOn(), lineup.leave) > 0;
		if (!joined && !left || mode == Online) return;
		panels.showSeats(seatLooks());
		lineUpANewRace();
	}

	/** Each seat's card on this computer: who (a player or AI) and with what. */
	function seatLooks():Array<SeatLook> {
		return [for (seat in 0...lineup.seats) {
			var controller = lineup.controllerIn(seat);
			var isHuman = lineup.isHuman(seat);
			var kind = DriverCharacters.kindOf(seed, seat);
			{
				who: isHuman ? Words.driverName(seat, "", true, false) : Words.aiKinds[kind],
				how: controller != null ? Words.controllerName(controller) : (isHuman ? Words.anyControls : Words.aiKindsAre[kind]),
				isAPerson: isHuman,
				isOurs: isHuman
			};
		}];
	}

	// ---- Presses ----

	/** A gamepad's A says yes to the panel showing: start, resume, or race again. */
	function pressYes() {
		switch mode {
			case ChoosingTrack: toDrivers();
			case ChoosingDrivers | Paused: startRacing();
			case RaceOver: raceAgain();
			case Online: if (panels.isShowingTheTracks()) online.doneWithTracks();
			case Racing:
		}
	}

	/** Racing (again): sound wakes up too (the first time, the press of Start is what browsers wait for). */
	function startRacing() {
		mode = Racing;
		show.sound.wake(Paint.liveries.length);
		steps.startAfresh();
		panels.hideAll();
		Browser.document.body.focus();
	}

	function raceAgain() {
		lineUpANewRace();
		startRacing();
	}

	/** Pausing works only during a race; pressing it again resumes. Online the race can't stop: a menu opens instead. */
	function pressPause() {
		switch mode {
			case Racing:
				mode = Paused;
				show.sound.rest();
				panels.showPause(false, show.sound.isOn);
			case Paused: startRacing();
			case Online: online.pressPause(show.sound.isOn);
			case _:
		}
	}

	/** Sound off, or back on, from a key, a pad button or the pause panel. */
	function toggleSound() {
		show.sound.toggle();
		panels.showSoundAs(show.sound.isOn);
	}

	// ---- Online ----

	/** Into an online room; sound wakes now (this press is what browsers wait for). When the room is left, back to the start. */
	function goOnline(how:HowToJoin) {
		mode = Online;
		show.sound.wake(Paint.liveries.length);
		online = new OnlineRace({tracks: tracks, racingLines: racingLines, show: show, panels: panels, controls: controls, lineup: lineup, whenGone: backFromOnline});
		online.join(how);
	}

	/** There is a server here: the drivers panel offers racing online, and a friend's link opens on its own panel. */
	function onlineIsHere() {
		panels.offerOnline();
		if (OnlineServer.invitation() != null && mode == ChoosingTrack) panels.showInvitation();
	}

	/** Back to the track cards: no invitation any more (declined, or that race has been left). */
	function forgetTheInvitation() {
		OnlineServer.forgetInvitation();
		showTrackCards();
	}

	function backFromOnline() {
		online = null;
		previewTrack(chosenTrack);
		forgetTheInvitation();
	}
}
