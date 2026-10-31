package shunt.online;

import shunt.ai.AiDriver;
import shunt.ai.RacingLine;
import shunt.car.CarInput;
import shunt.online.InputQueue.NumberedInputs;
import shunt.online.Messages;
import shunt.race.Race;
import shunt.track.Track;

/**
 * A browser's own copy of an online race, run ahead of the server so its
 * people's cars answer their controls at once (SPEC.md §9).
 *
 * Every tick it steps the race with this browser's inputs, which it also
 * numbers and keeps. When a snapshot comes from the server (always a
 * little in the past), it goes back to it, forgets the inputs the server
 * has used, and runs the rest again on top: so it ends up where the
 * server will be once those inputs reach it. AI cars are predicted
 * exactly (their drivers are made from the same seed and remember
 * nothing); other people's cars carry on with the last input they sent.
 */
class Prediction {
	public final race:Race;
	final me:String;
	final seed:Int;
	final line:RacingLine;
	var seats:Array<SeatHolder>;
	var drivers:Array<Null<AiDriver>>;
	var othersLastInputs:Array<CarInput> = [];
	final notYetUsed:Array<NumberedInputs> = [];
	var nextNumber = 0;

	/** The race a `RaceStart` describes, seen from the browser of session `me`. */
	public function new(track:Track, line:RacingLine, start:RaceStart, me:String) {
		race = new Race(track, {cars: start.seats.length, laps: track.laps, seed: start.seed});
		this.me = me;
		this.seed = start.seed;
		this.line = line;
		reseat(start.seats);
	}

	/** Seats changed during the race (someone left): AI drivers take the empty ones. */
	public function reseat(seats:Array<SeatHolder>) {
		this.seats = seats;
		drivers = SeatDrivers.forSeats(seats, seed, line);
	}

	/** The seats this browser drives, its first person's first. */
	public function mySeats():Array<Int> {
		var mine = [for (seat in 0...seats.length) if (seats[seat].owner == me) seat];
		mine.sort((one, other) -> seats[one].person - seats[other].person);
		return mine;
	}

	/** One tick ahead with this browser's inputs (one per person); returns them numbered, to send. */
	public function stepWith(myInputs:Array<CarInput>):NumberedInputs {
		var numbered:NumberedInputs = {number: nextNumber++, inputs: myInputs};
		notYetUsed.push(numbered);
		race.step(everyonesInput(myInputs));
		return numbered;
	}

	/** Back to the server's snapshot, then this browser's inputs that it hasn't used yet, run again. */
	public function catchUpWith(snapshot:Snapshot) {
		var usedUpTo = snapshot.usedUpTo.get(me) ?? -1;
		while (notYetUsed.length > 0 && notYetUsed[0].number <= usedUpTo) notYetUsed.shift();
		othersLastInputs = snapshot.lastInputs;
		race.restoreState(snapshot.state);
		for (numbered in notYetUsed) race.step(everyonesInput(numbered.inputs));
	}

	function everyonesInput(myInputs:Array<CarInput>):Array<CarInput> {
		return [for (seat in 0...seats.length) inputFor(seat, myInputs)];
	}

	/** A seat's input: this browser's person's, its AI driver's, or another person's last. */
	function inputFor(seat:Int, myInputs:Array<CarInput>):CarInput {
		var holder = seats[seat];
		if (holder.owner == me) return InputQueue.personsInput(myInputs, holder.person);
		var driver = drivers[seat];
		if (driver != null) return driver.inputFor(race, seat);
		return othersLastInputs[seat] ?? CarInputs.nothingPressed;
	}

	/** Some numbered inputs as one batch to send. */
	public static function batchOf(numbered:Array<NumberedInputs>):InputBatch {
		return {firstNumber: numbered[0].number, ticks: [for (entry in numbered) entry.inputs]};
	}
}
