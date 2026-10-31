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
 * The race uses one entry per tick, in order. If none has arrived in time,
 * the last one is used again (the driver most likely kept their foot down).
 * Every input is tidied first: it came over the network, from anyone.
 */
class InputQueue {
	final waiting:Array<NumberedInputs> = [];
	var lastUsed:Array<CarInput> = [];

	/** The number of the newest input that arrived, and of the last one used (-1: none yet). */
	var newestArrived = -1;
	public var usedUpTo(default, null) = -1;

	public function new() {}

	/** A batch has arrived: anything new goes in the queue, and if too much waits, the oldest goes. */
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
		while (waiting.length > OnlineTuning.mostInputsWaiting) waiting.shift();
	}

	/** A batch has a whole number to start from and a list of ticks (it came from the network, so it is checked). */
	static function isWellMade(batch:Dynamic):Bool {
		return batch != null && Std.isOfType(batch.firstNumber, Int) && Std.isOfType(batch.ticks, Array);
	}

	/** This tick's inputs: the next in the queue, or the last ones again if none has come. */
	public function next():Array<CarInput> {
		var entry = waiting.shift();
		if (entry == null) return lastUsed;
		usedUpTo = entry.number;
		lastUsed = entry.inputs;
		return lastUsed;
	}

	/** One person's input from a tick's inputs (nothing pressed, if that person sent none). */
	public static function personsInput(inputs:Array<CarInput>, person:Int):CarInput {
		return person < inputs.length ? inputs[person] : CarInputs.nothingPressed;
	}
}
