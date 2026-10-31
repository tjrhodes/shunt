package hud;

import js.html.Element;
import shunt.race.Race;
import view.Paint;

/**
 * One person's plate in the HUD: in their car's colour, with their tag
 * ("P2") when several are racing, their position, their lap, and their
 * car's damage.
 */
class PlayerPlate {
	public final plate:Element;
	final seat:Int;
	final tag:Element;
	final position:Element;
	final lap:Element;
	final damage:DamageOutline;

	public function new(seat:Int, hud:Element) {
		this.seat = seat;
		plate = Dom.make("div", "plate plate-standing", null, hud);
		plate.style.setProperty("--player", Paint.css(Paint.liveries[seat].colour));
		tag = Dom.make("span", "plate-tag", Words.playerTag(seat), plate);
		position = Hud.figure(plate, Words.position);
		lap = Hud.figure(plate, Words.lap);
		damage = new DamageOutline(plate);
	}

	/** Shows the plate (or hides it, for an AI seat), in its corner of the screen, with or without its tag. */
	public function place(isShown:Bool, corner:Int, withTag:Bool) {
		plate.hidden = !isShown;
		plate.dataset.corner = '$corner';
		tag.hidden = !withTag;
	}

	/** Brings the figures up to date with the race. */
	public function update(race:Race) {
		var me = race.racer(seat);
		Dom.setText(position, Words.outOf(race.state.order.indexOf(seat) + 1, race.state.racers.length));
		Dom.setText(lap, Words.outOf(Std.int(Math.max(1, Math.min(me.lapsStarted, race.state.laps))), race.state.laps));
		damage.show(me.car);
	}
}
