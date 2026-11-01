package hud;

import js.Browser;
import js.html.Element;
import shunt.online.Messages.RoomView;
import shunt.race.Laps;
import shunt.race.Race;
import shunt.race.StartLights;
import shunt.track.Track;
import view.Paint;

/** What each panel's buttons do; the game decides (on this computer or online). */
typedef PanelActions = {
	final chooseTrack:Int -> Void;
	final start:() -> Void;
	final resume:() -> Void;
	final toggleSound:() -> Void;
	final raceAgain:() -> Void;
	final changeTrack:() -> Void;
	final quickMatch:() -> Void;
	final raceFriends:() -> Void;
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
 * The panels over the track: the start panel (the track, the seats, how to
 * drive, and racing online), the online room, the pause panel, and the
 * results. One shows at a time, or none while racing.
 */
class Panels {
	final holder:Element;
	final everyPanel:Array<Element> = [];
	final startPanel:Element;
	final roomPanel:Element;
	final pausePanel:Element;
	final resultsPanel:Element;
	final startTracks:TrackPicker;
	final startSeats:SeatCards;
	final onlineBox:Element;
	final joinFriendsButton:Element;
	final room:RoomParts;
	final pause:PauseParts;
	final results:ResultsParts;

	public function new(holder:Element, tracks:Array<Track>, actions:PanelActions) {
		this.holder = holder;
		startPanel = panel(Words.gameName, "panel-start");
		Dom.make("p", "panel-tagline", Words.tagline, startPanel);
		startTracks = new TrackPicker(startPanel, tracks, actions.chooseTrack);
		startSeats = new SeatCards(startPanel);
		Dom.make("p", "panel-help", Words.joinHint, startPanel);
		Dom.button(Words.start, "button button-go button-start", startPanel, actions.start);
		onlineBox = onlineChoices(actions);
		joinFriendsButton = onlineBox.querySelector(".button-join");
		for (line in Words.howToDrive) Dom.make("p", "panel-help", line, startPanel);
		room = new RoomParts(roomPanel = panel(Words.online, "panel-room"), tracks, actions);
		pause = new PauseParts(pausePanel = panel(Words.paused, "panel-pause"), actions);
		results = new ResultsParts(resultsPanel = panel(Words.results, "panel-results"), actions);
	}

	/** Racing online, in the start panel: hidden until the page knows there is a server to race on. */
	function onlineChoices(actions:PanelActions):Element {
		var box = Dom.make("div", "online-choices", null, startPanel);
		box.hidden = true;
		Dom.make("h2", "panel-subtitle", Words.raceOnline, box);
		Dom.make("p", "panel-tagline only-invited", Words.invited, box);
		Dom.button(Words.joinFriends, "button button-go button-join only-invited", box, actions.joinFriends);
		Dom.button(Words.raceAlone, "button only-invited", box, actions.raceAlone);
		var row = Dom.make("div", "button-row not-invited", null, box);
		Dom.button(Words.quickMatch, "button", row, actions.quickMatch);
		Dom.button(Words.raceFriends, "button", row, actions.raceFriends);
		Dom.make("p", "panel-help not-invited", Words.onlineHelp, box);
		return box;
	}

	/**
	 * There is a server to race on. Opened from a friend's link, the start
	 * panel is only about joining them (the stylesheet hides the rest), so
	 * nobody starts a race on their own by mistake.
	 */
	public function offerOnline(hasAnInvitation:Bool) {
		onlineBox.hidden = false;
		startPanel.classList.toggle("is-invited", hasAnInvitation);
		if (!startPanel.hidden) showOnly(startPanel, hasAnInvitation ? joinFriendsButton : null);
	}

	// ---- On this computer ----

	/** The start panel, with the track chosen and the seats as they are. */
	public function showStart(chosenTrack:Int, seats:Array<SeatLook>) {
		startTracks.mark(chosenTrack, true);
		startSeats.show(seats);
		showOnly(startPanel, startPanel.classList.contains("is-invited") ? joinFriendsButton : null);
	}

	/** The seats changed while the start panel shows. */
	public function showSeats(seats:Array<SeatLook>) {
		startSeats.show(seats);
	}

	/** The pause panel: on this computer it can restart; online the race carries on, and you can leave. */
	public function showPause(isOnline:Bool, soundIsOn:Bool) {
		pause.show(isOnline, soundIsOn);
		showOnly(pausePanel);
	}

	public function showSoundAs(isOn:Bool) {
		pause.showSoundAs(isOn);
	}

	public function hideAll() {
		showOnly(null);
	}

	/** The results, in finishing order. Online, only the host can start the next race. */
	public function showResults(race:Race, drivers:Drivers, ?online:{isHost:Bool}) {
		results.show(race, drivers, online);
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
		room.show(view, seats, isHost, link);
		if (holder.querySelector(".panel:not([hidden])") != roomPanel) showOnly(roomPanel);
	}

	/** Something went wrong online: what it means, and (small) the reason given. */
	public function showCantConnect(reason:String) {
		room.showProblem(Words.cantConnect, reason);
		showOnly(roomPanel);
	}

	/** Whether a panel shows that a press of yes (a gamepad's A) shouldn't go through: the online room, where only the host's start counts. */
	public function isShowingTheRoom():Bool {
		return !roomPanel.hidden;
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
		if (wanted == null) return;
		var main = focusOn ?? firstShowing(wanted.querySelectorAll(".button-go:not(.button-join)"));
		if (main != null) main.focus();
	}

	static function firstShowing(buttons:js.html.NodeList):Null<Element> {
		for (index in 0...buttons.length) if (!(cast buttons.item(index) : Element).hidden) return cast buttons.item(index);
		return null;
	}
}

/** A button per track, side by side under a label; pressing one chooses it. Online only the host may. */
class TrackPicker {
	final buttons:Array<Element>;

	public function new(parent:Element, tracks:Array<Track>, choose:Int -> Void) {
		var picker = Dom.make("div", "track-picker", null, parent);
		picker.setAttribute("role", "group");
		picker.setAttribute("aria-label", Words.track);
		buttons = [for (index in 0...tracks.length) Dom.button(Words.trackChoice(tracks[index].name, tracks[index].laps), "button track-choice", picker, () -> choose(index))];
	}

	/** Marks the track chosen; the buttons work only for whoever may choose. */
	public function mark(chosen:Int, mayChoose:Bool) {
		for (index in 0...buttons.length) {
			buttons[index].setAttribute("aria-pressed", '${index == chosen}');
			buttons[index].toggleAttribute("disabled", !mayChoose);
		}
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

/** The online room panel's parts. */
class RoomParts {
	final panel:Element;
	final status:Element;
	final reason:Element;
	final linkRow:Element;
	final link:Element;
	final copyButton:Element;
	final tracks:TrackPicker;
	final seats:SeatCards;
	final startButton:Element;
	final leaveButton:Element;

	public function new(panel:Element, everyTrack:Array<Track>, actions:PanelActions) {
		this.panel = panel;
		status = Dom.make("p", "panel-tagline", null, panel);
		reason = Dom.make("p", "panel-help room-reason", null, panel);
		linkRow = Dom.make("div", "room-link", null, panel);
		Dom.make("p", "panel-help", Words.roomLink, linkRow);
		link = Dom.make("code", "room-link-text", null, linkRow);
		copyButton = Dom.button(Words.copy, "button", linkRow, copyTheLink);
		tracks = new TrackPicker(panel, everyTrack, actions.chooseTrack);
		seats = new SeatCards(panel);
		startButton = Dom.button(Words.start, "button button-go", panel, actions.start);
		leaveButton = Dom.button(Words.leave, "button", panel, actions.leave);
	}

	public function showConnecting() {
		showProblem(Words.connecting);
	}

	/** Just a line of words, perhaps a reason, and a way out: connecting, or a problem. */
	public function showProblem(words:String, ?why:String) {
		Dom.setText(status, words);
		Dom.setText(reason, why ?? "");
		reason.hidden = why == null;
		panel.classList.add("is-just-words");
	}

	public function show(view:RoomView, looks:Array<SeatLook>, isHost:Bool, roomLink:Null<String>) {
		Dom.setText(status, statusOf(view, isHost, Lambda.exists(looks, look -> look.isOurs)));
		reason.hidden = true;
		panel.classList.remove("is-just-words");
		linkRow.hidden = roomLink == null;
		Dom.setText(link, roomLink ?? "");
		Dom.setText(copyButton, Words.copy);
		tracks.mark(view.track, isHost);
		seats.show(looks);
		startButton.hidden = !isHost;
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
	final table:Element;
	final status:Element;
	final raceAgainButton:Element;
	final changeTrackButton:Element;
	final leaveButton:Element;

	public function new(panel:Element, actions:PanelActions) {
		table = Dom.make("ol", "results", null, panel);
		status = Dom.make("p", "panel-help", Words.waitingForTheHost, panel);
		raceAgainButton = Dom.button(Words.raceAgain, "button button-go", panel, actions.raceAgain);
		changeTrackButton = Dom.button(Words.changeTrack, "button", panel, actions.changeTrack);
		leaveButton = Dom.button(Words.leave, "button", panel, actions.leave);
	}

	/** The results, in finishing order; the buttons for on this computer, or online (the host starts the next race). */
	public function show(race:Race, drivers:Drivers, online:Null<{isHost:Bool}>) {
		table.innerHTML = "";
		for (place in 0...race.state.order.length) row(race, drivers, race.state.order[place], place + 1);
		raceAgainButton.hidden = online != null && !online.isHost;
		status.hidden = online == null || online.isHost;
		changeTrackButton.hidden = online != null;
		leaveButton.hidden = online == null;
	}

	/** A row: place, car colour, name, and race time (or how far it got). */
	function row(race:Race, drivers:Drivers, seat:Int, place:Int) {
		var racer = race.racer(seat);
		var row = Dom.make("li", drivers.isOurs(seat) ? "result is-player" : "result", null, table);
		row.style.setProperty("--player", Paint.css(Paint.liveries[seat].colour));
		Dom.make("span", "result-place", Words.place(place), row);
		Dom.make("span", "result-swatch", null, row).style.background = Paint.css(Paint.liveries[seat].colour);
		Dom.make("span", "result-name", drivers.nameOf(seat), row);
		var raceTime = (racer.finishTick - StartLights.greenTick) / Tick.perSecond;
		var howFar = Words.lap + " " + Words.outOf(Laps.lapsDone(racer), race.state.laps);
		Dom.make("span", "result-time", racer.finishTick >= 0 ? Words.raceTime(raceTime) : howFar, row);
	}
}
