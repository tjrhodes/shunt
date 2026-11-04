package hud;

import js.Browser;
import js.html.Element;
import online.HowToJoin;
import shunt.online.Messages.RoomView;
import shunt.race.Laps;
import shunt.race.Race;
import shunt.race.StartLights;
import shunt.track.Track;
import trophy.Trophy;
import view.Paint;
import hud.TrophyParts;

/** What each panel's buttons do; the game decides (on this computer or online). */
typedef PanelActions = {
	final chooseTrack:Int -> Void;

	/** A swipe on the cards: this many cards along (negative: back). */
	final moveAlongTheCards:Int -> Void;

	/** The ring has turned to face another card: the track behind should be that one. */
	final trackFacing:Int -> Void;
	final raceHere:() -> Void;
	final start:() -> Void;
	final resume:() -> Void;
	final toggleSound:() -> Void;
	final raceAgain:() -> Void;
	final changeTrack:() -> Void;
	final goOnline:HowToJoin -> Void;
	final joinFriends:() -> Void;
	final raceAlone:() -> Void;
	final leave:() -> Void;
}

/** How a seat's card looks: who drives it and with what, and whether they are a person, and one of ours. */
typedef SeatLook = {
	final who:String;
	final how:String;
	final isAPerson:Bool;
	final isOurs:Bool;
}

/** Who each car in the results was, and which were ours. */
typedef Drivers = {
	final nameOf:Int -> String;
	final isOurs:Int -> Bool;
}

/**
 * The panels over the track. Starting a race goes in stages, each with
 * room to breathe (Tom, 2 Nov): first a track, from a carousel of cards;
 * then the drivers, seat by seat, and racing here or online. A link from a
 * friend opens on its own small panel instead. Then the online room, the
 * pause panel, and the results. One shows at a time, or none while racing.
 */
class Panels {
	final holder:Element;
	final everyPanel:Array<Element> = [];
	final trackPanel:Element;
	final driversPanel:Element;
	final invitePanel:Element;
	final roomPanel:Element;
	final pausePanel:Element;
	final resultsPanel:Element;
	final trackCards:TrackCards;
	final tracksGo:Element;
	var trophyButton:Element;
	final soundCorner:SoundCorner;
	final trophyPanel:Element;
	final standingsPanel:Element;
	final trophySetup:TrophySetup;
	final standings:TrophyStandings;

	/** The trophy the trophy panels last showed. */
	var trophyShown:Null<Trophy> = null;
	final tracks:Array<Track>;
	final drivers:DriverParts;
	final room:RoomParts;
	final pause:PauseParts;
	final results:ResultsParts;

	public function new(holder:Element, tracks:Array<Track>, actions:PanelActions, trophyActions:TrophyActions) {
		this.holder = holder;
		this.tracks = tracks;
		soundCorner = new SoundCorner(holder.parentElement, actions.toggleSound);
		trackPanel = panel(Words.chooseATrack, "panel-tracks");
		trackCards = new TrackCards(trackPanel, tracks, actions.chooseTrack, actions.moveAlongTheCards, actions.trackFacing);
		tracksGo = tracksButtons(actions, trophyActions);
		trophySetup = new TrophySetup(trophyPanel = panel(Words.trophy, "panel-trophy"), tracks, trophyActions);
		standings = new TrophyStandings(standingsPanel = panel(Words.standings, "panel-results panel-standings"), trophyActions, () -> trophyShown);
		drivers = new DriverParts(driversPanel = panel(Words.drivers, "panel-drivers"), actions);
		invitePanel = invitation(actions);
		room = new RoomParts(roomPanel = panel(Words.online, "panel-room"), actions);
		pause = new PauseParts(pausePanel = panel(Words.paused, "panel-pause"), actions);
		results = new ResultsParts(resultsPanel = panel(Words.results, "panel-results"), actions);
	}

	/** Under the track cards: race on the one chosen, or start a trophy instead. Returns the go button. */
	function tracksButtons(actions:PanelActions, trophyActions:TrophyActions):Element {
		var row = Dom.make("div", "button-row", null, trackPanel);
		trophyButton = Dom.button(Words.trophy, "button", row, trophyActions.start);
		return Dom.button(Words.thisTrack, "button button-go", row, actions.raceHere);
	}

	/** The panel a friend's link opens on: just joining them, or racing alone instead. */
	function invitation(actions:PanelActions):Element {
		var box = panel(Words.gameName, "panel-invite");
		Dom.make("p", "panel-tagline", Words.invited, box);
		Dom.button(Words.joinFriends, "button button-go", box, actions.joinFriends);
		Dom.button(Words.raceAlone, "button", box, actions.raceAlone);
		return box;
	}

	/** There is a server to race on: the drivers panel offers racing online. */
	public function offerOnline() {
		drivers.offerOnline();
	}

	// ---- Starting a race ----

	/**
	 * The first stage: the track cards, the chosen one marked and in the
	 * middle. When choosing a track for something else (the online room's, a
	 * trophy race's) the go button says so, and there's no trophy button.
	 */
	public function showTracks(chosen:Int, ?goWords:String) {
		Dom.setText(tracksGo, goWords ?? Words.thisTrack);
		trophyButton.hidden = goWords != null;
		showOnly(trackPanel);
		trackCards.mark(chosen);
	}

	/** Moves anything moving in the panels on by some seconds (the ring of track cards, while it shows). */
	public function animate(seconds:Float) {
		if (!trackPanel.hidden) trackCards.animate(seconds);
	}

	/** How far the ring of track cards has turned, while it shows (the world behind follows it), or nothing. */
	public function ringTurn():Null<Float> {
		return trackPanel.hidden ? null : trackCards.turnNow();
	}

	/** The chosen track changed while the cards show. */
	public function markTrack(chosen:Int) {
		trackCards.mark(chosen);
	}

	/** The second stage: the drivers, for a race on a track (its line says which, and in a trophy which race). */
	public function showDrivers(chosen:Int, seats:Array<SeatLook>, ?line:String) {
		drivers.show(tracks[chosen], seats, line);
		showOnly(driversPanel);
	}

	// ---- Trophies ----

	/** A trophy's first stage: how many races, which tracks. */
	public function showTrophy(trophy:Trophy) {
		trophyShown = trophy;
		trophySetup.show(trophy);
		showOnly(trophyPanel);
	}

	/** The trophy's standings, after a race (and its winner after the last). */
	public function showStandings(trophy:Trophy, drivers:Drivers) {
		trophyShown = trophy;
		standings.show(trophy, drivers, tracks[trophy.nextTrack()]);
		showOnly(standingsPanel);
	}

	/** The seats changed while the drivers show. */
	public function showSeats(seats:Array<SeatLook>) {
		drivers.showSeats(seats);
	}

	/** Opened from a friend's link. */
	public function showInvitation() {
		showOnly(invitePanel);
	}

	/** Which stage of starting shows: the tracks, the drivers, or neither. */
	public function isShowingTheTracks():Bool {
		return !trackPanel.hidden;
	}

	/** The pause panel: on this computer it can restart; online the race carries on, and you can leave. */
	public function showPause(isOnline:Bool, soundIsOn:Bool) {
		pause.show(isOnline, soundIsOn);
		showOnly(pausePanel);
	}

	public function showSoundAs(isOn:Bool) {
		pause.showSoundAs(isOn);
		soundCorner.showSoundAs(isOn);
	}

	public function hideAll() {
		showOnly(null);
	}

	/** The results, in finishing order. Online, only the host can start the next race. */
	public function showResults(race:Race, drivers:Drivers, ?online:{isHost:Bool}, isInATrophy = false) {
		results.show(race, drivers, online, isInATrophy);
		showOnly(resultsPanel);
	}

	// ---- Online ----

	/** Waiting to be let in. */
	public function showConnecting() {
		room.showConnecting();
		showOnly(roomPanel);
	}

	/** The online room before a race: its link, who sits where, the track, and starting. */
	public function showRoom(view:RoomView, seats:Array<SeatLook>, isHost:Bool, link:Null<String>) {
		room.show(view, tracks[view.track], seats, isHost, link);
		if (holder.querySelector(".panel:not([hidden])") != roomPanel) showOnly(roomPanel);
	}

	/** A quick match's countdown, ticking down while the room shows. */
	public function showCountdown(seconds:Float) {
		if (!roomPanel.hidden) room.showCountdown(seconds);
	}

	/** Something went wrong online: what it means, and (small) the reason given. */
	public function showCantConnect(reason:String) {
		room.showProblem(Words.cantConnect, reason);
		showOnly(roomPanel);
	}

	// ---- Every panel ----

	/** A titled panel, hidden until wanted. */
	function panel(title:String, className:String):Element {
		var box = Dom.make("section", 'panel $className', null, holder);
		Dom.make("h1", "panel-title", title, box);
		box.hidden = true;
		everyPanel.push(box);
		return box;
	}

	/** Shows one panel (or none) and hides the rest; the holder dims the track only while a panel shows. Focus goes to its main button. */
	function showOnly(wanted:Null<Element>, ?focusOn:Element) {
		for (box in everyPanel) box.hidden = box != wanted;
		holder.classList.toggle("is-showing", wanted != null);
		Browser.document.body.classList.toggle("is-starting", [trackPanel, trophyPanel, driversPanel, invitePanel, roomPanel].contains(wanted));
		if (wanted == null) return;
		var main = focusOn ?? firstShowing(wanted.querySelectorAll(".button-go:not(.button-join)"));
		if (main != null) main.focus();
	}

	static function firstShowing(buttons:js.html.NodeList):Null<Element> {
		for (index in 0...buttons.length) if (!(cast buttons.item(index) : Element).hidden) return cast buttons.item(index);
		return null;
	}
}

/** A card per seat, in its car's colour, saying who drives it and with what. */
class SeatCards {
	final cards:Array<Element>;

	public function new(parent:Element) {
		var picker = Dom.make("div", "seat-picker", null, parent);
		picker.setAttribute("aria-label", Words.drivers);
		picker.setAttribute("aria-live", "polite");
		cards = [for (seat in 0...Paint.liveries.length) Dom.make("div", "seat", null, picker)];
		for (seat in 0...cards.length) cards[seat].style.setProperty("--player", Paint.css(Paint.liveries[seat].colour));
	}

	public function show(looks:Array<SeatLook>) {
		for (seat in 0...cards.length) {
			var card = cards[seat];
			card.classList.toggle("is-human", looks[seat].isAPerson);
			card.classList.toggle("is-ours", looks[seat].isOurs);
			card.innerHTML = "";
			Dom.make("span", "seat-who", looks[seat].who, card);
			Dom.make("span", "seat-how", looks[seat].how, card);
		}
	}
}

/** The drivers panel's parts: the track it's for, the seats, starting, going back, and racing online. */
class DriverParts {
	final trackName:Element;
	final seats:SeatCards;
	final onlineBox:Element;

	public function new(panel:Element, actions:PanelActions) {
		trackName = Dom.make("p", "panel-tagline", null, panel);
		seats = new SeatCards(panel);
		Dom.make("p", "panel-help", Words.joinHint, panel);
		var buttons = Dom.make("div", "button-row", null, panel);
		Dom.button(Words.back, "button", buttons, actions.changeTrack);
		Dom.button(Words.start, "button button-go", buttons, actions.start);
		onlineBox = onlineChoices(panel, actions);
		for (line in Words.howToDrive) Dom.make("p", "panel-help", line, panel);
	}

	/** Racing online: hidden until the page knows there is a server to race on. */
	static function onlineChoices(panel:Element, actions:PanelActions):Element {
		var box = Dom.make("div", "online-choices", null, panel);
		box.hidden = true;
		Dom.make("h2", "panel-subtitle", Words.raceOnline, box);
		var row = Dom.make("div", "button-row", null, box);
		Dom.button(Words.quickMatch, "button", row, () -> actions.goOnline(QuickMatch));
		Dom.button(Words.raceFriends, "button", row, () -> actions.goOnline(NewRoom));
		Dom.make("p", "panel-help", Words.onlineHelp, box);
		return box;
	}

	public function offerOnline() {
		onlineBox.hidden = false;
	}

	public function show(track:Track, looks:Array<SeatLook>, ?line:String) {
		Dom.setText(trackName, line ?? Words.racingOn(track.name, track.laps));
		seats.show(looks);
	}

	public function showSeats(looks:Array<SeatLook>) {
		seats.show(looks);
	}
}

/** The online room panel's parts. */
class RoomParts {
	final panel:Element;
	final status:Element;
	final reason:Element;
	final trackRow:Element;
	final changeTrackButton:Element;
	final linkRow:Element;
	final link:Element;
	final copyButton:Element;
	final seats:SeatCards;
	final startButton:Element;
	final leaveButton:Element;

	public function new(panel:Element, actions:PanelActions) {
		this.panel = panel;
		status = Dom.make("p", "panel-tagline", null, panel);
		reason = Dom.make("p", "panel-help room-reason", null, panel);
		linkRow = Dom.make("div", "room-link", null, panel);
		Dom.make("p", "panel-help", Words.roomLink, linkRow);
		link = Dom.make("code", "room-link-text", null, linkRow);
		copyButton = Dom.button(Words.copy, "button", linkRow, copyTheLink);
		var trackBox = Dom.make("div", "room-track", null, panel);
		trackRow = Dom.make("div", "room-track-what", null, trackBox);
		changeTrackButton = Dom.button(Words.changeTrack, "button", trackBox, actions.changeTrack);
		seats = new SeatCards(panel);
		startButton = Dom.button(Words.start, "button button-go", panel, actions.start);
		leaveButton = Dom.button(Words.leave, "button", panel, actions.leave);
	}

	public function showConnecting() {
		showProblem(Words.connecting);
	}

	public function showCountdown(seconds:Float) {
		Dom.setText(status, Words.startsIn(Math.max(0, seconds)));
	}

	/** Just a line of words, perhaps a reason, and a way out: connecting, or a problem. */
	public function showProblem(words:String, ?why:String) {
		Dom.setText(status, words);
		Dom.setText(reason, why ?? "");
		reason.hidden = why == null;
		panel.classList.add("is-just-words");
	}

	public function show(view:RoomView, track:Track, looks:Array<SeatLook>, isHost:Bool, roomLink:Null<String>) {
		Dom.setText(status, statusOf(view, isHost, Lambda.exists(looks, look -> look.isOurs)));
		reason.hidden = true;
		panel.classList.remove("is-just-words");
		linkRow.hidden = roomLink == null;
		Dom.setText(link, roomLink ?? "");
		Dom.setText(copyButton, Words.copy);
		showTrack(track);
		changeTrackButton.hidden = !isHost;
		seats.show(looks);
		startButton.hidden = !isHost;
	}

	/** The room's track: a small map of it, its name, and its laps and length (the host can change it, on the cards). */
	function showTrack(track:Track) {
		if (trackRow.dataset.track == track.name) return;
		trackRow.dataset.track = track.name;
		trackRow.innerHTML = "";
		trackRow.appendChild(TrackCards.mapOf(track));
		Dom.make("span", "room-track-name", track.name, trackRow);
		Dom.make("span", "room-track-laps", Words.lapsAndLength(track.laps, track.length), trackRow);
	}

	/** One line on what happens next. */
	static function statusOf(view:RoomView, isHost:Bool, haveASeat:Bool):String {
		if (!haveASeat && view.phase == Racing) return Words.watching;
		if (view.startsIn >= 0) return Words.startsIn(view.startsIn);
		if (isHost) return Words.youAreTheHost;
		return view.quick ? Words.waitingToStart : Words.waitingForTheHost;
	}

	/** Copies the link, for pasting into a message (the browser may refuse: then it can still be selected by hand). */
	function copyTheLink() {
		var clipboard:Dynamic = Browser.navigator.clipboard;
		if (clipboard == null) return;
		(clipboard.writeText(link.textContent) : js.lib.Promise<Dynamic>).then(_ -> Dom.setText(copyButton, Words.copied), _ -> null);
	}
}

/** The pause panel's parts. */
class PauseParts {
	final restartButton:Element;
	final soundButton:Element;
	final leaveButton:Element;

	public function new(panel:Element, actions:PanelActions) {
		Dom.button(Words.resume, "button button-go", panel, actions.resume);
		restartButton = Dom.button(Words.restart, "button", panel, actions.raceAgain);
		soundButton = Dom.button(Words.soundIsOn, "button", panel, actions.toggleSound);
		leaveButton = Dom.button(Words.leave, "button", panel, actions.leave);
	}

	public function show(isOnline:Bool, soundIsOn:Bool) {
		restartButton.hidden = isOnline;
		leaveButton.hidden = !isOnline;
		showSoundAs(soundIsOn);
	}

	/** The sound button says whether sound is on. */
	public function showSoundAs(isOn:Bool) {
		Dom.setText(soundButton, isOn ? Words.soundIsOn : Words.soundIsOff);
		soundButton.setAttribute("aria-pressed", '$isOn');
	}
}

/** The results panel's parts. */
class ResultsParts {
	final headline:Element;
	final trackLine:Element;
	final table:Element;
	final status:Element;
	final raceAgainButton:Element;
	final changeTrackButton:Element;
	final leaveButton:Element;

	public function new(panel:Element, actions:PanelActions) {
		headline = panel.querySelector(".panel-title");
		trackLine = Dom.make("p", "panel-tagline", null, panel);
		table = Dom.make("ol", "results", null, panel);
		status = Dom.make("p", "panel-help", Words.waitingForTheHost, panel);
		raceAgainButton = Dom.button(Words.raceAgain, "button button-go", panel, actions.raceAgain);
		changeTrackButton = Dom.button(Words.changeTrack, "button", panel, actions.changeTrack);
		leaveButton = Dom.button(Words.leave, "button", panel, actions.leave);
	}

	/** The results, in finishing order; the buttons for on this computer (in a trophy: on to the standings), or online (the host starts the next race). */
	public function show(race:Race, drivers:Drivers, online:Null<{isHost:Bool}>, isInATrophy:Bool) {
		table.innerHTML = "";
		Dom.setText(raceAgainButton, isInATrophy ? Words.standings : Words.raceAgain);
		Dom.setText(headline, Words.winner(drivers.nameOf(race.state.order[0])));
		Dom.setText(trackLine, Words.racingOn(race.track.name, race.state.laps));
		for (place in 0...race.state.order.length) row(race, drivers, race.state.order[place], place + 1);
		raceAgainButton.hidden = online != null && !online.isHost;
		status.hidden = online == null || online.isHost;
		changeTrackButton.hidden = online != null || isInATrophy;
		leaveButton.hidden = online == null;
	}

	/** A row: place, car colour, name, and race time (or how far it got). */
	function row(race:Race, drivers:Drivers, seat:Int, place:Int) {
		var racer = race.racer(seat);
		var raceTime = (racer.finishTick - StartLights.greenTick) / Tick.perSecond;
		var howFar = Words.lap + " " + Words.outOf(Laps.lapsDone(racer), race.state.laps);
		placeRow(table, drivers, seat, place, drivers.nameOf(seat), racer.finishTick >= 0 ? Words.raceTime(raceTime) : howFar);
	}

	/** A row of a table of places (results, trophy standings): place, car colour, name, and a figure on the right. */
	public static function placeRow(table:Element, drivers:Drivers, seat:Int, place:Int, name:String, figure:String) {
		var row = Dom.make("li", drivers.isOurs(seat) ? "result is-player" : "result", null, table);
		row.style.setProperty("--player", Paint.css(Paint.liveries[seat].colour));
		Dom.make("span", "result-place", Words.place(place), row);
		Dom.make("span", "result-swatch", null, row).style.background = Paint.css(Paint.liveries[seat].colour);
		Dom.make("span", "result-name", name, row);
		Dom.make("span", "result-time", figure, row);
	}
}
