package hud;

import js.html.Element;
import shunt.track.Track;
import hud.Award.AwardKind;
import hud.Panels;
import tournament.Tournament;

/** What the tournament's panels do; the game decides. */
typedef TournamentActions = {
	/** A new tournament, from the track cards (or after one is won). */
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
 * The tournament's first stage (Tom, 4 Nov): how many races, and which tracks.
 * They start as a random pick; each can be swapped for another on the
 * track cards, or the whole lot shuffled.
 */
class TournamentSetup {
	final lengthButtons:Array<Element>;
	final list:Element;
	final tracks:Array<Track>;
	final swap:Int -> Void;

	public function new(panel:Element, tracks:Array<Track>, actions:TournamentActions) {
		this.tracks = tracks;
		swap = actions.swap;
		Dom.make("p", "panel-tagline", Words.tournamentRules, panel);
		var lengths = Dom.make("div", "tournament-lengths", null, panel);
		lengths.setAttribute("role", "group");
		lengthButtons = [for (races in Tournament.lengths) Dom.button(Words.races(races), "button", lengths, () -> actions.makeItLong(races))];
		list = Dom.make("ol", "tournament-tracks", null, panel);
		var buttons = Dom.make("div", "button-row", null, panel);
		Dom.button(Words.back, "button", buttons, actions.leave);
		Dom.button(Words.shuffle, "button", buttons, actions.shuffle);
		Dom.button(Words.chooseDrivers, "button button-go", buttons, actions.toDrivers);
	}

	/** The tournament as it stands: its length marked, and a row per race. */
	public function show(tournament:Tournament) {
		for (index in 0...lengthButtons.length) lengthButtons[index].setAttribute("aria-pressed", '${Tournament.lengths[index] == tournament.tracks.length}');
		list.innerHTML = "";
		for (race in 0...tournament.tracks.length) row(race, tracks[tournament.tracks[race]]);
	}

	/** A race's row: its number, the track's little map, name and laps, and a button to swap it. */
	function row(race:Int, track:Track) {
		var row = Dom.make("li", "tournament-track", null, list);
		Dom.make("span", "tournament-track-number", '${race + 1}', row);
		row.appendChild(TrackCards.mapOf(track));
		Dom.make("span", "tournament-track-name", track.name, row);
		Dom.make("span", "tournament-track-laps", Words.lapsAndLength(track.laps, track.length), row);
		Dom.button(Words.swap, "button tournament-swap", row, () -> swap(race));
	}
}

/**
 * The tournament's standings, after each race: everyone's points, first to
 * last. When the last race is run, the winner, and a new tournament or back to
 * the tracks.
 */
class TournamentStandings {
	final headline:Element;
	final runSoFar:Element;
	final table:Element;
	final goButton:Element;
	final award:Award;

	public function new(panel:Element, actions:TournamentActions, tournament:() -> Tournament) {
		headline = panel.querySelector(".panel-title");
		award = new Award(panel);
		runSoFar = Dom.make("p", "panel-tagline", null, panel);
		table = Dom.make("ol", "results standings", null, panel);
		goButton = Dom.button("", "button button-go", panel, () -> tournament().isOver() ? actions.start() : actions.nextRace());
		Dom.button(Words.leaveTheTournament, "button", panel, actions.leave);
	}

	/** The standings now, and what the go button does next: the next race, or a new tournament. Once it's over, the award for the best of us; returned, for the fireworks. */
	public function show(tournament:Tournament, drivers:Drivers, nextTrack:Track):AwardKind {
		var standings = tournament.standings();
		var ourBest = Lambda.findIndex(standings, drivers.isOurs) + 1;
		var won = tournament.isOver() ? Award.forPlace(ourBest) : Nothing;
		award.show(won);
		Dom.setText(headline, tournament.isOver() ? Words.tournamentWinner(drivers.nameOf(standings[0])) : Words.standings);
		Dom.setText(runSoFar, Words.racesRun(tournament.racesRun, tournament.tracks.length));
		Dom.setText(goButton, tournament.isOver() ? Words.newTournament : Words.nextRace(nextTrack.name));
		table.innerHTML = "";
		for (place in 0...standings.length) row(tournament, drivers, standings[place], place + 1);
		return won;
	}

	/** A row: place, car colour, name (with wins, if any), and points. */
	function row(tournament:Tournament, drivers:Drivers, seat:Int, place:Int) {
		var name = drivers.nameOf(seat) + (tournament.wins[seat] > 0 ? " · " + Words.wins(tournament.wins[seat]) : "");
		ResultsParts.placeRow(table, drivers, seat, place, name, Words.points(tournament.points[seat]));
	}
}
