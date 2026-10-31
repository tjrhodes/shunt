import hud.Hud;
import hud.Panels;
import hud.Panels.PanelActions;
import input.PlayerControls;
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
 * The game in the browser (SPEC.md §1): one race at a time on the track
 * chosen, the player in seat 0 and AI drivers in the others, drawn every
 * frame between the last two ticks. Everything about the race itself is in
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
	final controls:PlayerControls;
	final steps = new FixedSteps();
	final carViews:Array<CarView>;
	final oilView = new OilView();
	final effects = new Effects();
	var race:Race;
	var drivers:Array<AiDriver>;
	var posesBefore:Array<Pose>;
	var mode = WaitingToStart;
	var chosenTrack = 0;
	var lastFrameTime = -1.0;

	public function new(tracks:Array<Track>, page:PageParts) {
		this.tracks = tracks;
		racingLines = tracks.map(track -> new RacingLine(track));
		world = new World(page.stage);
		hud = new Hud(page.hud);
		panels = new Panels(page.panels, tracks, panelActions());
		controls = new PlayerControls(page.stage, page.brakePad, page.pauseButton);
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
		if (controls.pauseWasJustPressed()) pressPause();
		showEverything();
		Browser.window.requestAnimationFrame(frame);
	}

	function runTheTicksDue(now:Float) {
		for (_ in 0...steps.ticksDue(now)) oneTick();
		if (race.state.phase == Finished) {
			mode = RaceOver;
			panels.showResults(race);
		}
	}

	/** Remembers where every car is, moves the race on a tick, and shows what it left behind. */
	function oneTick() {
		posesBefore = posesNow();
		race.step(everyonesInput());
		effects.afterTick(race);
		for (event in race.events) if (event.kind == CarHit || event.kind == WallHit) feelTheHit(event);
	}

	/** A hit dents the cars in it, and shakes the view if the player's car was one of them. */
	function feelTheHit(hit:RaceEvent) {
		for (seat in [hit.racer, hit.other]) {
			if (seat < 0) continue;
			var car = race.racer(seat).car;
			carViews[seat].dent(car.inCarTerms(hit.point - car.position), hit.strength);
		}
		if (involvesThePlayer(hit.racer, hit.other)) world.shakeFor(hit.strength / hardestShake);
	}

	/** The player's input for seat 0; each AI driver's for the others. */
	function everyonesInput():Array<CarInput> {
		return [controls.carInput()].concat([for (seat in 1...race.state.racers.length) drivers[seat - 1].inputFor(race, seat)]);
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
		hud.update(race);
		world.draw();
	}

	/** A fresh race on the chosen track, on a new seed, with new AI drivers, lights red. */
	function lineUpANewRace() {
		var seed = Std.random(1000000000) + 1;
		var track = tracks[chosenTrack];
		race = new Race(track, {cars: Paint.liveries.length, laps: track.laps, seed: seed});
		drivers = [for (seat in 1...race.state.racers.length) new AiDriver(DriverCharacters.forSeat(seed, seat), racingLines[chosenTrack], seat)];
		posesBefore = posesNow();
		effects.clear();
		for (view in carViews) view.mendDents();
	}

	function startRacing() {
		mode = Racing;
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
			panels.showPause();
		} else if (mode == Paused) startRacing();
	}

	function posesNow():Array<Pose> {
		return [for (racer in race.state.racers) {position: racer.car.position, heading: racer.car.heading}];
	}

	static function involvesThePlayer(racer:Int, other:Int):Bool {
		return racer == 0 || other == 0;
	}
}
