import hud.Hud;
import hud.Panels;
import hud.Panels.PanelActions;
import input.Controller;
import input.Controls;
import seats.Lineup;
import js.Browser;
import shunt.ai.AiDriver;
import shunt.ai.DriverCharacter;
import shunt.ai.RacingLine;
import shunt.car.CarInput;
import shunt.maths.Numbers.partWay;
import shunt.maths.Numbers.wrapAngle;
import shunt.maths.Vector;
import shunt.race.Race;
import shunt.race.RaceEvent;
import shunt.race.RaceState.Phase;
import shunt.track.Track;
import view.CarView;
import view.OilView;
import view.Paint;
import view.World;
import sound.Sound;
import view.effects.Effects;

using shunt.car.CarFrame;

/** Where a car was at the end of a tick: enough to draw it between ticks. */
typedef Pose = {
	final position:Vector;
	final heading:Float;
}

/** What the game is doing. */
enum GameMode {
	WaitingToStart;
	Racing;
	Paused;
	RaceOver;
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
 * The game in the browser (SPEC.md §1, §9): one race at a time on the track
 * chosen, with people in the seats they joined (or one person alone) and AI
 * drivers in the rest, drawn every frame between the last two ticks. Everything about the race itself is in
 * the shared simulation; this only feeds it inputs and shows what it does.
 */
class Game {
	/** A hit on the player's car this hard (m/s change of speed) or harder shakes the view fully. */
	static inline final hardestShake = 12.0;

	final tracks:Array<Track>;
	final racingLines:Array<RacingLine>;
	final world:World;
	final hud:Hud;
	final panels:Panels;
	final controls:Controls;
	final lineup = new Lineup(Paint.liveries.length);
	final steps = new FixedSteps();
	final carViews:Array<CarView>;
	final oilView = new OilView();
	final effects = new Effects();
	final sound:Sound;
	var race:Race;

	/** The AI driver in each seat, or nothing where a person drives. */
	var drivers:Array<Null<AiDriver>>;
	var posesBefore:Array<Pose>;
	var mode = WaitingToStart;
	var chosenTrack = 0;
	var lastFrameTime = -1.0;

	public function new(tracks:Array<Track>, page:PageParts) {
		this.tracks = tracks;
		racingLines = tracks.map(track -> new RacingLine(track));
		world = new World(page.stage);
		hud = new Hud(page.hud, lineup.seats);
		panels = new Panels(page.panels, tracks, panelActions());
		controls = new Controls(page.stage, page.brakePad, page.pauseButton);
		sound = new Sound(lineup.isHuman);
		carViews = [for (livery in Paint.liveries) new CarView(livery)];
		for (view in carViews) world.scene.add(view.whole);
		world.scene.add(oilView.whole);
		world.scene.add(effects.whole);
		chooseTrack(0);
		Browser.window.requestAnimationFrame(frame);
	}

	function panelActions():PanelActions {
		return {
			chooseTrack: chooseTrack,
			start: startRacing,
			resume: startRacing,
			restart: raceAgain,
			toggleSound: toggleSound,
			raceAgain: raceAgain,
			changeTrack: () -> chooseTrack(chosenTrack)
		};
	}

	/** Shows a track with the cars on its grid, waiting for the start. */
	function chooseTrack(index:Int) {
		chosenTrack = index;
		world.showTrack(tracks[index]);
		lineUpANewRace();
		mode = WaitingToStart;
		panels.showSeats(lineup);
		panels.showStart(index);
	}

	/** One frame: run the ticks that are due and move the sparks and smoke on (while racing), check for pause, and draw. */
	function frame(now:Float) {
		var secondsSinceLastFrame = lastFrameTime < 0 ? 0 : Math.min(0.1, (now - lastFrameTime) / 1000);
		lastFrameTime = now;
		if (mode == Racing) {
			runTheTicksDue(now);
			effects.animate(secondsSinceLastFrame);
		}
		if (mode == WaitingToStart) takeSeats();
		if (controls.pauseWasJustPressed()) pressPause();
		if (controls.muteWasJustPressed()) toggleSound();
		if (controls.confirmWasJustPressed()) pressYes();
		showEverything();
		Browser.window.requestAnimationFrame(frame);
	}

	function runTheTicksDue(now:Float) {
		for (_ in 0...steps.ticksDue(now)) oneTick();
		if (race.state.phase == Finished) {
			mode = RaceOver;
			sound.rest();
			panels.showResults(race, lineup);
		}
	}

	/** Remembers where every car is, moves the race on a tick, and shows what it left behind. */
	function oneTick() {
		posesBefore = posesNow();
		race.step(everyonesInput());
		effects.afterTick(race);
		for (event in race.events) sound.hear(event);
		for (event in race.events) if (event.kind == CarHit || event.kind == WallHit) feelTheHit(event);
	}

	/** A hit dents the cars in it, and shakes the view if the player's car was one of them. */
	function feelTheHit(hit:RaceEvent) {
		for (seat in [hit.racer, hit.other]) {
			if (seat < 0) continue;
			var car = race.racer(seat).car;
			carViews[seat].dent(car.inCarTerms(hit.point - car.position), hit.strength);
		}
		if (lineup.isHuman(hit.racer) || (hit.other >= 0 && lineup.isHuman(hit.other))) world.shakeFor(hit.strength / hardestShake);
	}

	/** Each seat's input: from its person's controllers, or from its AI driver. */
	function everyonesInput():Array<CarInput> {
		return [for (seat in 0...race.state.racers.length) inputFor(seat)];
	}

	function inputFor(seat:Int):CarInput {
		var driver = drivers[seat];
		return driver != null ? driver.inputFor(race, seat) : controls.carInputFrom(lineup.controllersFor(seat, controls.every()));
	}

	/** Before a race, a press of go on a controller takes a seat and a press of brake gives it back; the panel and HUD follow. */
	function takeSeats() {
		var joined = Lambda.count(controls.throttleJustPressedOn(), lineup.join) > 0;
		var left = Lambda.count(controls.brakeJustPressedOn(), lineup.leave) > 0;
		if (!joined && !left) return;
		panels.showSeats(lineup);
		lineUpANewRace();
	}

	/** Every car drawn part way between its last two ticks, then the oil, the HUD, and the frame. */
	function showEverything() {
		var share = mode == Racing ? steps.shareIntoTheNextTick() : 1;
		var posesAfter = posesNow();
		for (seat in 0...carViews.length) {
			var before = posesBefore[seat];
			var after = posesAfter[seat];
			var heading = before.heading + wrapAngle(after.heading - before.heading) * share;
			carViews[seat].show(race.racer(seat).car, heading, before.position + (after.position - before.position) * share);
		}
		oilView.show(race.state.oil);
		if (mode == Racing) sound.follow(race);
		hud.update(race);
		world.draw();
	}

	/** A fresh race on the chosen track, on a new seed, with new AI drivers, lights red. */
	function lineUpANewRace() {
		var seed = Std.random(1000000000) + 1;
		var track = tracks[chosenTrack];
		race = new Race(track, {cars: Paint.liveries.length, laps: track.laps, seed: seed});
		drivers = [for (seat in 0...race.state.racers.length) lineup.isHuman(seat) ? null : new AiDriver(DriverCharacters.forSeat(seed, seat), racingLines[chosenTrack], seat)];
		hud.seat(lineup);
		posesBefore = posesNow();
		effects.clear();
		for (view in carViews) view.mendDents();
	}

	/** A gamepad's A says yes to the panel showing: start, resume, or race again. */
	function pressYes() {
		switch mode {
			case WaitingToStart: startRacing();
			case Paused: startRacing();
			case RaceOver: raceAgain();
			case Racing:
		}
	}

	/** Racing (again): sound wakes up too (the first time, the press of Start is what browsers wait for). */
	function startRacing() {
		mode = Racing;
		sound.wake(carViews.length);
		steps.startAfresh();
		panels.hideAll();
		Browser.document.body.focus();
	}

	function raceAgain() {
		lineUpANewRace();
		startRacing();
	}

	/** Pausing works only during a race; pressing it again resumes. */
	function pressPause() {
		if (mode == Racing) {
			mode = Paused;
			sound.rest();
			panels.showSoundAs(sound.isOn);
			panels.showPause();
		} else if (mode == Paused) startRacing();
	}

	/** Sound off, or back on, from a key, a pad button or the pause panel. */
	function toggleSound() {
		sound.toggle();
		panels.showSoundAs(sound.isOn);
	}

	function posesNow():Array<Pose> {
		return [for (racer in race.state.racers) {position: racer.car.position, heading: racer.car.heading}];
	}
}
