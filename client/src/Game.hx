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
import shunt.maths.Vector;
import shunt.race.Race;
import shunt.track.Track;
import hud.TournamentParts;
import tournament.Tournament;
import view.Backdrops;
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

	/** A tournament's first stage: how many races, which tracks. */
	ChoosingTournament;

	/** A tournament's standings, between races and at the end. */
	TournamentStandings;
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
	final backdrops:Backdrops;

	/** Whether the 3D view is busy showing other tracks to take their pictures (the front card's picture covers it meanwhile). */
	var isTakingPictures = false;
	var race:Race;

	/** The AI driver in each seat, or nothing where a person drives. */
	var drivers:Array<Null<AiDriver>>;
	var posesBefore:Array<Pose>;
	var mode = ChoosingTrack;

	/** The seed of the race lined up: its AI drivers (and so their kinds, on the seat cards) come from it. */
	var seed = 1;
	var chosenTrack = 0;

	/** The track the world behind shows, and the race lined up on: the chosen one, except while the ring of cards is still turning towards it. */
	var shownTrack = -1;
	var lastFrameTime = -1.0;
	var online:Null<OnlineRace> = null;

	/** The tournament being raced, if one is. */
	var tournament:Null<Tournament> = null;

	/** While a tournament race's track is being swapped on the cards: which race. */
	var swappingRace:Null<Int> = null;

	public function new(tracks:Array<Track>, page:PageParts) {
		this.tracks = tracks;
		racingLines = tracks.map(track -> new RacingLine(track));
		show = new Show(page.stage, page.hud, isOneOfOurs);
		panels = new Panels(page.panels, tracks, panelActions(), tournamentActions());
		controls = new Controls(page.stage, page.brakePad, page.pauseButton);
		backdrops = new Backdrops(page.stage, page.panels);
		panels.showSoundAs(show.sound.isOn);
		previewTrack(0);
		showTrackBehind(0);
		showTrackCards();
		OnlineServer.lookForOne().then(isThere -> if (isThere) onlineIsHere());
		Browser.window.requestAnimationFrame(frame);
	}

	/** Every button does the same thing on this computer and online, where it means asking the room. */
	function panelActions():PanelActions {
		return {
			chooseTrack: pickCard, moveAlongTheCards: moveAlongTheCards, trackFacing: showTrackBehind,
			raceHere: () -> mode == Online ? online.doneWithTracks() : trackChosen(),
			start: () -> mode == Online ? online.startRace() : startRacing(),
			resume: () -> mode == Online ? online.closeMenu() : startRacing(),
			toggleSound: toggleSound,
			raceAgain: () -> mode == Online ? online.startRace() : raceAgainOrStandings(),
			changeTrack: () -> mode == Online ? online.browseTracks() : backToChoosing(),
			goOnline: goOnline,
			joinFriends: () -> goOnline(RoomById(OnlineServer.invitation())),
			raceAlone: forgetTheInvitation,
			leave: () -> if (online != null) online.leave()
		};
	}

	/**
	 * Whether a person here drives a seat in the race. Not in a demo
	 * (`?demo` on the page's address): there every car is an AI driver, for
	 * recording the game in action (the Lab page's screenshots and video).
	 */
	function isDrivenHere(seat:Int):Bool {
		return lineup.isHuman(seat) && Browser.location.search.indexOf("demo") < 0;
	}

	/** In a close demo (`?demo=close`), the camera this much closer, following the action; its spot eases this share of the way each frame. */
	static inline final closeDemoZoom = 2.6;
	static inline final followEasing = 0.06;
	var actionSpot:Null<Vector> = null;

	/**
	 * In a close demo, while racing, the camera follows the two cars nearest
	 * each other (where the contact is), easing from pair to pair: for the
	 * Lab page's action shots. Everywhere else it shows the whole track.
	 */
	function followTheAction() {
		if (mode != Racing || Browser.location.search.indexOf("demo=close") < 0) return;
		var spot = nearestPairMiddle();
		actionSpot = actionSpot == null ? spot : actionSpot + (spot - actionSpot) * followEasing;
		show.closeUpOn(actionSpot, closeDemoZoom);
	}

	/** The point halfway between the two cars nearest each other. */
	function nearestPairMiddle():Vector {
		var cars = [for (racer in race.state.racers) racer.car.position];
		var best = {a: cars[0], b: cars[1]};
		for (i in 0...cars.length) for (j in i + 1...cars.length) if (cars[i].distanceTo(cars[j]) < best.a.distanceTo(best.b)) best = {a: cars[i], b: cars[j]};
		return (best.a + best.b) * 0.5;
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

	/** A track chosen on the cards: the ring turns to it (and the track behind follows, see `showTrackBehind`). */
	function previewTrack(index:Int) {
		chosenTrack = (index % tracks.length + tracks.length) % tracks.length;
		panels.markTrack(chosenTrack);
	}

	/**
	 * The track behind the cards, with the cars on its grid: it changes as the
	 * ring turns past each card (under the crossfade, see `Backdrops`).
	 * Online, the room's track shows the same way while the host chooses.
	 */
	function showTrackBehind(index:Int) {
		if (mode == Online) return online.showTrackBehind(index);
		if (index == shownTrack) return;
		shownTrack = index;
		show.showTrack(tracks[shownTrack]);
		lineUpANewRace();
	}

	/** A card pressed: the first press chooses it, a second press on the chosen one goes on to the drivers (online, `OnlineRace` decides). */
	function pickCard(index:Int) {
		if (mode == Online) online.pickCard(index);
		else if (index == chosenTrack) trackChosen();
		else previewTrack(index);
	}

	/** The second stage: the drivers, for a race on the chosen track. */
	function toDrivers() {
		showTrackBehind(chosenTrack);
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
		showTheWorldBehindTheCards();
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

	/** A race over: in a tournament it scores, then the results. */
	function finished() {
		mode = RaceOver;
		show.sound.rest();
		if (tournament != null) tournament.score(race.state.order);
		panels.showResults(race, driversHere(), null, tournament != null);
	}

	/** Who drives each car on this computer, by name: "You" alone, "Player 2", or an AI driver's kind. */
	function driversHere():Drivers {
		var isAlone = lineup.people() == 1;
		return {nameOf: seat -> Words.driverName(seat, Words.aiKinds[DriverCharacters.kindOf(seed, seat)], lineup.isHuman(seat), isAlone), isOurs: lineup.isHuman};
	}

	/** Every car drawn part way between its last two ticks. */
	function showEverything() {
		followTheAction();
		var share = mode == Racing ? steps.shareIntoTheNextTick() : 1;
		var posesNow = Poses.of(race.state);
		show.draw(race, [for (seat in 0...posesNow.length) Poses.between(posesBefore[seat], posesNow[seat], share)], mode == Racing);
	}

	/** A fresh race on the track shown, on a new seed, with new AI drivers, lights red. */
	function lineUpANewRace() {
		seed = tournament != null ? tournament.seedForARace() : Std.random(1000000000) + 1;
		var track = tracks[shownTrack];
		race = new Race(track, {cars: Paint.liveries.length, laps: track.laps, seed: seed});
		drivers = [for (seat in 0...race.state.racers.length) isDrivenHere(seat) ? null : new AiDriver(DriverCharacters.forSeat(seed, seat), racingLines[shownTrack], seat)];
		show.hud.seat(lineup.humanSeats());
		posesBefore = Poses.of(race.state);
		show.freshRace();
	}

	// ---- Behind the cards ----

	/** While the cards show, the world behind follows the ring's turn (crossfading pictures, see `Backdrops`); on this computer, pictures still missing are taken. */
	function showTheWorldBehindTheCards() {
		var turn = panels.ringTurn();
		if (turn == null) return backdrops.hide();
		if (mode == ChoosingTrack) takeAPicture(turn);
		backdrops.show(turn, tracks.length, isTakingPictures);
	}

	/**
	 * One track's picture a frame, while the ring is at rest: first the track
	 * showing, then (once that picture is ready to cover the view) each of
	 * the others, shown with its cars on the grid just long enough to draw.
	 * When the ring moves, or every picture is taken, the view goes back.
	 */
	function takeAPicture(turn:Float) {
		var next = Backdrops.isAtRest(turn) ? backdrops.nextToTake(tracks.length, shownTrack) : null;
		if (next == null) return stopTakingPictures();
		if (next != shownTrack && !backdrops.isReady(shownTrack)) return;
		if (next != shownTrack) drawForAPicture(next);
		else showEverything();
		backdrops.keep(next, show.drawing());
	}

	/** Another track in the view, its cars lined up, drawn (only the picture of it is seen). */
	function drawForAPicture(index:Int) {
		isTakingPictures = true;
		show.showTrack(tracks[index]);
		var grid = new Race(tracks[index], {cars: Paint.liveries.length, laps: tracks[index].laps, seed: 1});
		show.draw(grid, Poses.of(grid.state), false);
	}

	/** Back to the track that should be showing, drawn now, so the view is right the moment the cover goes. */
	function stopTakingPictures() {
		if (!isTakingPictures) return;
		isTakingPictures = false;
		show.showTrack(tracks[shownTrack]);
		showEverything();
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
			case ChoosingTrack: trackChosen();
			case ChoosingDrivers | Paused: startRacing();
			case RaceOver: raceAgainOrStandings();
			case ChoosingTournament: tournamentDrivers();
			case TournamentStandings: tournament.isOver() ? startATournament() : nextTournamentRace();
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

	/** The chosen card is the one: race on it, or (swapping a tournament race's track) that race's track. */
	function trackChosen() {
		if (swappingRace != null) changeTheTournament(() -> tournament.swap(swappingRace, chosenTrack));
		else toDrivers();
	}

	/** Back from the drivers (or results) to choosing: the tournament's tracks if one is being set up, else the cards. */
	function backToChoosing() {
		if (tournament != null) showTheTournament();
		else showTrackCards();
	}

	/** After a race, the go button: in a tournament, on to the standings; else (and from the pause panel's restart) the same race again. */
	function raceAgainOrStandings() {
		if (tournament != null && mode == RaceOver) showTheStandings();
		else raceAgain();
	}

	// ---- Tournaments ----

	/** What the tournament panels' buttons do. */
	function tournamentActions():TournamentActions {
		return {
			start: startATournament,
			makeItLong: races -> changeTheTournament(() -> tournament.resize(races)),
			shuffle: () -> changeTheTournament(() -> tournament.shuffle()),
			swap: swapATrack,
			toDrivers: tournamentDrivers,
			nextRace: nextTournamentRace,
			leave: leaveTheTournament
		};
	}

	/** A new tournament: five races on tracks picked at random, to change if wanted. */
	function startATournament() {
		tournament = new Tournament(tracks.length, Tournament.lengths[1], Paint.liveries.length, Std.random);
		showTheTournament();
	}

	function showTheTournament() {
		mode = ChoosingTournament;
		swappingRace = null;
		panels.showTournament(tournament);
	}

	/** A change to the tournament's tracks, and the panel shows it. */
	function changeTheTournament(change:() -> Void) {
		change();
		showTheTournament();
	}

	/** Choosing another track for one of the tournament's races: the cards, starting at the one it has now. */
	function swapATrack(race:Int) {
		mode = ChoosingTrack;
		swappingRace = race;
		previewTrack(tournament.tracks[race]);
		panels.showTracks(chosenTrack, Words.useThisTrack);
	}

	/** On to the drivers for the tournament's first race (lined up afresh, so its AI drivers are the tournament's). */
	function tournamentDrivers() {
		previewTrack(tournament.nextTrack());
		mode = ChoosingDrivers;
		showTrackBehind(chosenTrack);
		lineUpANewRace();
		panels.showDrivers(chosenTrack, seatLooks(), Words.tournamentRace(tournament.racesRun + 1, tournament.tracks.length, tracks[chosenTrack].name, tracks[chosenTrack].laps));
	}

	function showTheStandings() {
		mode = TournamentStandings;
		panels.showStandings(tournament, driversHere());
	}

	/** Straight into the tournament's next race, on its track, with the same drivers. */
	function nextTournamentRace() {
		previewTrack(tournament.nextTrack());
		showTrackBehind(chosenTrack);
		lineUpANewRace();
		startRacing();
	}

	function leaveTheTournament() {
		tournament = null;
		showTrackCards();
	}

	// ---- Online ----

	/** Into an online room; sound wakes now (this press is what browsers wait for). When the room is left, back to the start. */
	function goOnline(how:HowToJoin) {
		mode = Online;
		tournament = null;
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
		shownTrack = -1;
		showTrackBehind(chosenTrack);
		forgetTheInvitation();
	}
}
