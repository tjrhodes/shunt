package hud;

import js.html.Element;
import shunt.race.Laps;
import shunt.race.Race;
import shunt.race.StartLights;
import shunt.track.Track;
import view.Paint;

/** What each panel's buttons do; the game decides. */
typedef PanelActions = {
	final chooseTrack:Int -> Void;
	final start:() -> Void;
	final resume:() -> Void;
	final restart:() -> Void;
	final toggleSound:() -> Void;
	final raceAgain:() -> Void;
	final changeTrack:() -> Void;
}

/**
 * The panels over the track: the start panel (name, the track to race on,
 * and how to drive), the pause panel, and the results. One shows at a time,
 * or none while racing.
 */
class Panels {
	final holder:Element;
	final startPanel:Element;
	final pausePanel:Element;
	final resultsPanel:Element;
	final resultsTable:Element;
	final trackButtons:Array<Element>;
	final soundButton:Element;

	public function new(holder:Element, tracks:Array<Track>, actions:PanelActions) {
		this.holder = holder;
		startPanel = panel(Words.gameName, "panel-start");
		Dom.make("p", "panel-tagline", Words.tagline, startPanel);
		trackButtons = trackPicker(tracks, actions.chooseTrack);
		Dom.button(Words.start, "button button-go", startPanel, actions.start);
		for (line in Words.howToDrive) Dom.make("p", "panel-help", line, startPanel);
		pausePanel = panel(Words.paused, "panel-pause");
		soundButton = pauseButtonsIn(pausePanel, actions);
		resultsPanel = panel(Words.results, "panel-results");
		resultsTable = Dom.make("ol", "results", null, resultsPanel);
		Dom.button(Words.raceAgain, "button button-go", resultsPanel, actions.raceAgain);
		Dom.button(Words.changeTrack, "button", resultsPanel, actions.changeTrack);
	}

	/** Resume, restart and the sound button, in the pause panel; returns the sound button. */
	function pauseButtonsIn(pausePanel:Element, actions:PanelActions):Element {
		Dom.button(Words.resume, "button button-go", pausePanel, actions.resume);
		Dom.button(Words.restart, "button", pausePanel, actions.restart);
		return Dom.button(Words.soundIsOn, "button", pausePanel, actions.toggleSound);
	}

	/** The start panel, with the track chosen marked. */
	public function showStart(chosenTrack:Int) {
		for (index in 0...trackButtons.length) trackButtons[index].setAttribute("aria-pressed", '${index == chosenTrack}');
		showOnly(startPanel);
	}

	/** A button per track, side by side under a label; pressing one chooses it. */
	function trackPicker(tracks:Array<Track>, choose:Int -> Void):Array<Element> {
		var picker = Dom.make("div", "track-picker", null, startPanel);
		picker.setAttribute("role", "group");
		picker.setAttribute("aria-label", Words.track);
		return [for (index in 0...tracks.length) Dom.button(Words.trackChoice(tracks[index].name, tracks[index].laps), "button track-choice", picker, () -> choose(index))];
	}

	public function showPause() {
		showOnly(pausePanel);
	}

	/** The pause panel's sound button says whether sound is on. */
	public function showSoundAs(isOn:Bool) {
		Dom.setText(soundButton, isOn ? Words.soundIsOn : Words.soundIsOff);
		soundButton.setAttribute("aria-pressed", '$isOn');
	}

	public function hideAll() {
		showOnly(null);
	}

	/** The results, in finishing order: place, car, and race time (or how far it got). */
	public function showResults(race:Race) {
		resultsTable.innerHTML = "";
		for (place in 0...race.state.order.length) resultRow(race, race.state.order[place], place + 1);
		showOnly(resultsPanel);
	}

	function resultRow(race:Race, seat:Int, place:Int) {
		var racer = race.racer(seat);
		var livery = Paint.liveries[seat];
		var row = Dom.make("li", seat == 0 ? "result is-player" : "result", null, resultsTable);
		Dom.make("span", "result-place", Words.place(place), row);
		Dom.make("span", "result-swatch", null, row).style.background = Paint.css(livery.colour);
		Dom.make("span", "result-name", Words.driverName(seat, livery.number), row);
		var raceTime = (racer.finishTick - StartLights.greenTick) / Tick.perSecond;
		var howFar = Words.lap + " " + Words.outOf(Laps.lapsDone(racer), race.state.laps);
		Dom.make("span", "result-time", racer.finishTick >= 0 ? Words.raceTime(raceTime) : howFar, row);
	}

	/** A titled panel, hidden until wanted. */
	function panel(title:String, className:String):Element {
		var box = Dom.make("section", 'panel $className', null, holder);
		Dom.make("h1", "panel-title", title, box);
		box.hidden = true;
		return box;
	}

	/** Shows one panel (or none) and hides the rest; the holder dims the track only while a panel shows. */
	function showOnly(wanted:Null<Element>) {
		for (box in [startPanel, pausePanel, resultsPanel]) box.hidden = box != wanted;
		holder.classList.toggle("is-showing", wanted != null);
		if (wanted != null) wanted.querySelector(".button-go").focus();
	}
}
