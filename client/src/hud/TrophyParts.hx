package hud;

import js.html.Element;
import shunt.track.Track;
import hud.Panels;
import trophy.Trophy;

/** What the trophy's panels do; the game decides. */
typedef TrophyActions = {
	/** A new trophy, from the track cards (or after one is won). */
	final start:() -> Void;

	/** How many races: 3, 5 or 10. */
	final makeItLong:Int -> Void;

	final shuffle:() -> Void;

	/** Choose another track for a race (on the cards). */
	final swap:Int -> Void;

	/** On to the drivers, for the first race. */
	final toDrivers:() -> Void;

	final nextRace:() -> Void;
	final leave:() -> Void;
}

/**
 * The trophy's first stage (Tom, 4 Nov): how many races, and which tracks.
 * They start as a random pick; each can be swapped for another on the
 * track cards, or the whole lot shuffled.
 */
class TrophySetup {
	final lengthButtons:Array<Element>;
	final list:Element;
	final tracks:Array<Track>;
	final swap:Int -> Void;

	public function new(panel:Element, tracks:Array<Track>, actions:TrophyActions) {
		this.tracks = tracks;
		swap = actions.swap;
		Dom.make("p", "panel-tagline", Words.trophyRules, panel);
		var lengths = Dom.make("div", "trophy-lengths", null, panel);
		lengths.setAttribute("role", "group");
		lengthButtons = [for (races in Trophy.lengths) Dom.button(Words.races(races), "button", lengths, () -> actions.makeItLong(races))];
		list = Dom.make("ol", "trophy-tracks", null, panel);
		var buttons = Dom.make("div", "button-row", null, panel);
		Dom.button(Words.back, "button", buttons, actions.leave);
		Dom.button(Words.shuffle, "button", buttons, actions.shuffle);
		Dom.button(Words.chooseDrivers, "button button-go", buttons, actions.toDrivers);
	}

	/** The trophy as it stands: its length marked, and a row per race. */
	public function show(trophy:Trophy) {
		for (index in 0...lengthButtons.length) lengthButtons[index].setAttribute("aria-pressed", '${Trophy.lengths[index] == trophy.tracks.length}');
		list.innerHTML = "";
		for (race in 0...trophy.tracks.length) row(race, tracks[trophy.tracks[race]]);
	}

	/** A race's row: its number, the track's little map, name and laps, and a button to swap it. */
	function row(race:Int, track:Track) {
		var row = Dom.make("li", "trophy-track", null, list);
		Dom.make("span", "trophy-track-number", '${race + 1}', row);
		row.appendChild(TrackCards.mapOf(track));
		Dom.make("span", "trophy-track-name", track.name, row);
		Dom.make("span", "trophy-track-laps", Words.lapsAndLength(track.laps, track.length), row);
		Dom.button(Words.swap, "button trophy-swap", row, () -> swap(race));
	}
}

/**
 * The trophy's standings, after each race: everyone's points, first to
 * last. When the last race is run, the winner, and a new trophy or back to
 * the tracks.
 */
class TrophyStandings {
	final headline:Element;
	final runSoFar:Element;
	final table:Element;
	final goButton:Element;

	public function new(panel:Element, actions:TrophyActions, trophy:() -> Trophy) {
		headline = panel.querySelector(".panel-title");
		runSoFar = Dom.make("p", "panel-tagline", null, panel);
		table = Dom.make("ol", "results standings", null, panel);
		goButton = Dom.button("", "button button-go", panel, () -> trophy().isOver() ? actions.start() : actions.nextRace());
		Dom.button(Words.leaveTheTrophy, "button", panel, actions.leave);
	}

	/** The standings now, and what the go button does next: the next race, or a new trophy. */
	public function show(trophy:Trophy, drivers:Drivers, nextTrack:Track) {
		var standings = trophy.standings();
		Dom.setText(headline, trophy.isOver() ? Words.trophyWinner(drivers.nameOf(standings[0])) : Words.standings);
		Dom.setText(runSoFar, Words.racesRun(trophy.racesRun, trophy.tracks.length));
		Dom.setText(goButton, trophy.isOver() ? Words.newTrophy : Words.nextRace(nextTrack.name));
		table.innerHTML = "";
		for (place in 0...standings.length) row(trophy, drivers, standings[place], place + 1);
	}

	/** A row: place, car colour, name (with wins, if any), and points. */
	function row(trophy:Trophy, drivers:Drivers, seat:Int, place:Int) {
		var name = drivers.nameOf(seat) + (trophy.wins[seat] > 0 ? " · " + Words.wins(trophy.wins[seat]) : "");
		ResultsParts.placeRow(table, drivers, seat, place, name, Words.points(trophy.points[seat]));
	}
}
