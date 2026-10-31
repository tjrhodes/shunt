import hud.Hud;
import shunt.online.Pose;
import shunt.race.Race;
import shunt.race.RaceEvent;
import shunt.track.Track;
import sound.Sound;
import view.CarView;
import view.OilView;
import view.Paint;
import view.World;
import view.effects.Effects;

using shunt.car.CarFrame;

/**
 * Everything that shows a race and lets you hear it: the 3D world with
 * its cars, oil, sparks and smoke, the HUD, and the sound. It doesn't care
 * where the race comes from: a race on this computer (`Game`) or one
 * online (`online.OnlineRace`) is shown the same way.
 */
class Show {
	/** A hit on a person's car this hard (m/s change of speed) or harder shakes the view fully. */
	static inline final hardestShake = 12.0;

	public final sound:Sound;
	public final hud:Hud;
	final world:World;
	final carViews:Array<CarView>;
	final oilView = new OilView();
	final effects = new Effects();

	/** Whether a person (on this computer) drives a seat: their cars are loud, and their hits shake the view. */
	final isOneOfOurs:Int -> Bool;

	public function new(stage:js.html.Element, hudElement:js.html.Element, isOneOfOurs:Int -> Bool) {
		this.isOneOfOurs = isOneOfOurs;
		world = new World(stage);
		hud = new Hud(hudElement, Paint.liveries.length);
		sound = new Sound(isOneOfOurs);
		carViews = [for (livery in Paint.liveries) new CarView(livery)];
		for (view in carViews) world.scene.add(view.whole);
		world.scene.add(oilView.whole);
		world.scene.add(effects.whole);
	}

	public function showTrack(track:Track) {
		world.showTrack(track);
	}

	/** A new race: no sparks, smoke or skid marks left over, and every dent taken out. */
	public function freshRace() {
		effects.clear();
		for (view in carViews) view.mendDents();
	}

	/** After a tick of the race: what it left behind (skids, smoke), what it sounded like, and its hits felt. */
	public function afterTick(race:Race) {
		effects.afterTick(race);
		for (event in race.events) sound.hear(event);
		for (event in race.events) if (event.kind == CarHit || event.kind == WallHit) feelTheHit(race, event);
	}

	/** A hit dents the cars in it, and shakes the view if one of ours was in it. */
	function feelTheHit(race:Race, hit:RaceEvent) {
		for (seat in [hit.racer, hit.other]) {
			if (seat < 0) continue;
			var car = race.racer(seat).car;
			carViews[seat].dent(car.inCarTerms(hit.point - car.position), hit.strength);
		}
		if (isOneOfOurs(hit.racer) || (hit.other >= 0 && isOneOfOurs(hit.other))) world.shakeFor(hit.strength / hardestShake);
	}

	/** Moves the sparks and smoke on by some seconds. */
	public function animate(seconds:Float) {
		effects.animate(seconds);
	}

	/** Draws a frame: each car where it is to be shown, the oil, the HUD; engines and tyres heard while racing. */
	public function draw(race:Race, poses:Array<Pose>, isRacing:Bool) {
		for (seat in 0...carViews.length) carViews[seat].show(race.racer(seat).car, poses[seat].heading, poses[seat].position);
		oilView.show(race.state.oil);
		if (isRacing) sound.follow(race);
		hud.update(race);
		world.draw();
	}
}
