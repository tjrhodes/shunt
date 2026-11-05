package shunt.online;

import shunt.car.CarInput;
import shunt.online.Messages.InputBatch;

/** One tick's inputs from a browser (one per seat it drives), and its number. */
typedef NumberedInputs = {
	final number:Int;
	final inputs:Array<CarInput>;
}

/**
 * One browser's inputs, waiting at the server to be used (SPEC.md §9).
 *
 * Each input is for one tick: the browser numbers them, and the server uses
 * input number n on its tick n + `lag`, the same lag every time. If an input
 * isn't there in time, the last one is used again (the driver most likely
 * kept their foot down), and when it does arrive it is too late and goes.
 *
 * The lag stays put (Tom, 5 Nov: cars jumped online). Before, late inputs
 * were used anyway, later, so every late one added a tick to the lag, and
 * every change of lag moves the whole race in time on everyone's screen: a
 * stall of a sixth of a second jumped the cars metres. Now the lag only
 * changes a tick at a time, every half second at most: up when inputs have
 * come late lately, down when more than enough have been waiting.
 *
 * Every input is tidied first: it came over the network, from anyone.
 */
class InputQueue {
	final waiting:Array<NumberedInputs> = [];
	var lastUsed:Array<CarInput> = [];

	/** The number of the newest input that arrived, and of the last one whose tick has gone by (-1: none yet). */
	var newestArrived = -1;
	public var usedUpTo(default, null) = -1;

	/** Ticks between an input's number and the server tick it is used on; unknown until the first arrives. */
	var lag:Null<Int> = null;

	/** For the room's log: ticks whose inputs hadn't come in time, inputs that came too late, and inputs to spare, added up over the ticks asked. */
	public var late(default, null) = 0;
	public var dropped(default, null) = 0;
	public var waitingAddedUp(default, null) = 0;
	public var asked(default, null) = 0;

	/** The fewest inputs to spare at any tick lately (negative: one came late), and the most. */
	var fewestSpareLately = OnlineTuning.mostInputsWaiting;
	var mostSpareLately = -1000000;

	public function new() {}

	/** A batch has arrived: anything new goes in the queue (the newest few, if there are too many). */
	public function add(batch:InputBatch) {
		if (!isWellMade(batch)) return;
		var onlyTheLastFew = Std.int(Math.max(0, batch.ticks.length - OnlineTuning.mostInputsWaiting));
		for (index in onlyTheLastFew...batch.ticks.length) {
			var number = batch.firstNumber + index;
			if (number <= newestArrived) continue;
			var inputs:Array<CarInput> = Std.isOfType(batch.ticks[index], Array) ? batch.ticks[index] : [];
			waiting.push({number: number, inputs: inputs.slice(0, OnlineTuning.mostPeoplePerBrowser).map(CarInputs.tidied)});
			newestArrived = number;
		}
		while (waiting.length > 2 * OnlineTuning.mostInputsWaiting) waiting.shift();
	}

	/** A batch has a whole number to start from and a list of ticks (it came from the network, so it is checked). */
	static function isWellMade(batch:Dynamic):Bool {
		return batch != null && Std.isOfType(batch.firstNumber, Int) && Std.isOfType(batch.ticks, Array);
	}

	/** The inputs for server tick `tick`: the one numbered for it, or the last ones again if it hasn't come. */
	public function next(tick:Int):Array<CarInput> {
		asked++;
		if (lag == null && waiting.length > 0) lag = tick - waiting[0].number + OnlineTuning.inputsKeptWaiting;
		if (lag == null) return lastUsed;
		var wanted = tick - lag;
		throwAwayOlderThan(wanted);
		noteHowManyToSpare(wanted);
		usedUpTo = Std.int(Math.max(usedUpTo, wanted));
		if (waiting.length == 0 || waiting[0].number != wanted) return useTheLastAgain();
		lastUsed = waiting.shift().inputs;
		return lastUsed;
	}

	function useTheLastAgain():Array<CarInput> {
		late++;
		return lastUsed;
	}

	/** Inputs for ticks already gone by (they came too late, or the lag shrank past them). */
	function throwAwayOlderThan(wanted:Int) {
		while (waiting.length > 0 && waiting[0].number < wanted) {
			waiting.shift();
			dropped++;
		}
	}

	/** Notes how many inputs there are beyond the one wanted now; every half second the lag moves a tick if it should. */
	function noteHowManyToSpare(wanted:Int) {
		var spare = newestArrived - wanted;
		waitingAddedUp += Std.int(Math.max(0, spare));
		fewestSpareLately = Std.int(Math.min(fewestSpareLately, spare));
		mostSpareLately = Std.int(Math.max(mostSpareLately, spare));
		if (asked % OnlineTuning.queueWatchedForTicks == 0) settleTheLag();
	}

	/**
	 * Up a tick if an input came late lately, down a tick if more than enough
	 * were always to spare. If none came in time at all lately, the browser
	 * has fallen behind for good (it lost time): the lag catches up at once.
	 */
	function settleTheLag() {
		if (mostSpareLately < 0) lag += OnlineTuning.inputsKeptWaiting - mostSpareLately;
		else if (fewestSpareLately < 0) lag++;
		else if (fewestSpareLately > OnlineTuning.inputsKeptWaiting) lag--;
		fewestSpareLately = OnlineTuning.mostInputsWaiting;
		mostSpareLately = -1000000;
	}

	/** One person's input from a tick's inputs (nothing pressed, if that person sent none). */
	public static function personsInput(inputs:Array<CarInput>, person:Int):CarInput {
		return person < inputs.length ? inputs[person] : CarInputs.nothingPressed;
	}
}
