import Check.*;
import shunt.car.CarInput;
import shunt.online.InputQueue;
import shunt.online.OnlineTuning;
import shunt.online.RoomSeats;

/** Racing online (SPEC.md §9): rooms, seats, inputs over the network, and how well browsers predict the race. */
class OnlineTests {
	public static final all:Array<Check.Test> = [
		test("seats go a person each, in the order browsers came; the rest watch", seatsInArrivalOrder),
		test("the browser in longest is the host, and the next takes over when it leaves", hostHandsOver),
		test("only the host chooses the track and starts the race", onlyTheHostDecides),
		test("inputs are used in order, one a tick, the last again when none has come", inputsInOrder),
		test("a stall in a browser's inputs doesn't move the rest to other ticks", inputsKeepTheirTicks),
		test("too many waiting inputs: the oldest go; repeats are ignored; numbers are tidied", inputQueueGuards),
		test("with no delay, a browser predicts the server's race all but exactly", noDelayNoCorrection),
		test("someone leaving mid-race: an AI driver takes their car on to the finish", aiTakesOverALeaver),
		test("a quick match starts by itself once two people are in", quickMatchStartsItself),
		test("a room made for a tournament races its tracks in order, scores each race and tells everyone", aTournamentRoom),
		test("a room starts on the track asked for, if there is one", () -> {
			equal(new OnlineHarness(0.05, false, null, 7).room.view().track, 7, "the track chosen on the cards");
			equal(new OnlineHarness(0.05, true, null, 4).room.view().track, 4, "a quick match too");
			equal(new OnlineHarness(0.05, false, null, 99).room.view().track, 0, "no such track: the first");
			equal(new OnlineHarness(0.05, false, [3, 1, 2], 7).room.view().track, 3, "a tournament: its first track");
		}),
		test("with 50, 100 and 200 ms each way, browsers finish with the server's results, and corrections are small", racesOverDelay)
	];

	static final pressed:CarInput = {throttle: 1, brake: 0, steer: 0, recover: false};

	static function seatsInArrivalOrder() {
		var seats = new RoomSeats();
		for (session in ["a", "b", "c"]) seats.arrive(session);
		seats.want("a", 2);
		seats.want("b", 1);
		seats.want("c", 3);
		seats.seatEveryone();
		equal([for (holder in seats.seats) holder.owner].join(","), "a,a,b,c", "who sits where");
		equal(seats.seats[1].person, 1, "a's second person");
		equal(seats.peopleSeated(), 4, "people seated");
		equal(seats.peopleHere(), 6, "people here");
	}

	static function hostHandsOver() {
		var harness = new OnlineHarness(0, false);
		harness.arrive("a", 1);
		harness.arrive("b", 1);
		equal(harness.room.view().host, "a", "host at first");
		harness.room.depart("a");
		equal(harness.room.view().host, "b", "host after a leaves");
		equal(harness.room.view().seats[0].owner, "b", "b moves up to the first seat between races");
	}

	static function onlyTheHostDecides() {
		var harness = new OnlineHarness(0, false);
		harness.arrive("a", 1);
		harness.arrive("b", 1);
		harness.room.chooseTrack("b", {track: 1});
		equal(harness.room.view().track, 0, "track after b chooses");
		harness.room.chooseTrack("a", {track: 1});
		equal(harness.room.view().track, 1, "track after the host chooses");
		harness.room.startRace("b");
		equal(harness.room.view().phase, Gathering, "after b presses start");
		harness.room.startRace("a");
		equal(harness.room.view().phase, Racing, "after the host presses start");
	}

	static function inputsInOrder() {
		var queue = new InputQueue();
		var kept = OnlineTuning.inputsKeptWaiting;
		queue.add({firstNumber: 0, ticks: [[pressed], [CarInputs.nothingPressed]]});
		for (tick in 0...kept) queue.next(tick);
		equal(queue.next(kept)[0].throttle, 1.0, "the first input, once a few ticks are in hand");
		equal(queue.next(kept + 1)[0].throttle, 0.0, "the second, on the next tick");
		equal(queue.next(kept + 2)[0].throttle, 0.0, "none for this tick: the last again");
		equal(queue.usedUpTo, 2, "done with up to");
		queue.add({firstNumber: 2, ticks: [[CarInputs.nothingPressed], [pressed]]});
		equal(queue.next(kept + 3)[0].throttle, 1.0, "number 3 on its own tick (number 2 came too late, and went)");
	}

	static function inputQueueGuards() {
		var queue = new InputQueue();
		var kept = OnlineTuning.inputsKeptWaiting;
		queue.add({firstNumber: 0, ticks: [for (_ in 0...OnlineTuning.mostInputsWaiting + 5) [pressed]]});
		queue.add(null);
		queue.add(cast {firstNumber: "x", ticks: 3});
		for (tick in 0...kept + 1) queue.next(tick);
		equal(queue.usedUpTo, 5, "a huge batch: only its newest kept, so the first used is number 5");
		queue.add({firstNumber: 17, ticks: [[{throttle: 9, brake: -2, steer: 4, recover: false}]]});
		var wild = [for (tick in kept + 1...kept + 13) queue.next(tick)].pop()[0];
		equal(queue.usedUpTo, 17, "used up to");
		isTrue(wild.throttle == 1 && wild.brake == 0 && wild.steer == 1, "wild numbers tidied: " + haxe.Json.stringify(wild));
	}

	/** Inputs that stop for a sixth of a second, then all come at once (a stalled browser), don't change which tick each input is used on. */
	static function inputsKeepTheirTicks() {
		var queue = new InputQueue();
		var numbered = (number:Int) -> [{throttle: number / 1000, brake: 0.0, steer: 0.0, recover: false}];
		for (tick in 0...56) {
			if (tick < 30) queue.add({firstNumber: tick, ticks: [numbered(tick)]});
			if (tick == 48) queue.add({firstNumber: 30, ticks: [for (number in 30...49) numbered(number)]});
			if (tick > 48) queue.add({firstNumber: tick, ticks: [numbered(tick)]});
			if (tick == 55) equal(Math.round(queue.next(tick)[0].throttle * 1000), 55 - OnlineTuning.inputsKeptWaiting, "the input used on tick 55");
			else queue.next(tick);
		}
		isTrue(queue.late >= 18, 'the stalled ticks used the last input again (${queue.late} late)');
	}

	static function noDelayNoCorrection() {
		var harness = racingWith(0, 2);
		harness.runUntil(() -> false, 20);
		var biggest = Lambda.fold(harness.browsers[0].corrections, Math.max, 0.0);
		isTrue(harness.browsers[0].corrections.length > 100, "snapshots heard: " + harness.browsers[0].corrections.length);
		// Not quite zero: the other person's very latest input is a tick away even here, and a bump between the two can differ by millimetres.
		isTrue(biggest < 0.05, 'biggest correction under 5 cm, got $biggest m');
	}

	static function aiTakesOverALeaver() {
		var harness = racingWith(0.05, 2);
		harness.runUntil(() -> false, 8);
		harness.browsers.remove(harness.browsers[1]);
		harness.room.depart("b");
		harness.runUntil(() -> harness.room.view().phase == Results, 600);
		equal(harness.room.view().phase, Results, "the race finished");
		isTrue(harness.browsers[0].prediction.race.racer(1).lapsStarted >= harness.browsers[0].prediction.race.state.laps, "b's car did every lap");
	}

	static function quickMatchStartsItself() {
		var harness = new OnlineHarness(0.05, true);
		harness.arrive("a", 1);
		harness.runUntil(() -> false, OnlineTuning.quickMatchStartsAfterSeconds + 1);
		equal(harness.room.view().phase, Gathering, "alone, after the wait");
		harness.arrive("b", 1);
		harness.runUntil(() -> harness.room.view().phase == Racing, OnlineTuning.quickMatchStartsAfterSeconds + 1);
		equal(harness.room.view().phase, Racing, "with two");
	}

	static function aTournamentRoom() {
		var harness = new OnlineHarness(0.05, false, [2, 5, 1]);
		var a = harness.arrive("a", 1);
		harness.arrive("b", 1);
		equal(harness.room.view().track, 2, "the first race's track");
		harness.room.chooseTrack("a", {track: 7});
		equal(harness.room.view().track, 2, "the host can't change a tournament's track");
		harness.room.startRace("a");
		harness.runUntil(() -> a.room?.phase == Results, 600);
		equal(a.room.tournament.racesRun, 1, "races run, as the browser heard");
		equal(Lambda.fold(a.room.tournament.points, (points, sum) -> points + sum, 0), 6, "points shared out (3, 2, 1, 0)");
		harness.room.startRace("a");
		equal(harness.room.view().track, 5, "the second race's track");
	}

	static function racesOverDelay() {
		for (milliseconds in [50, 100, 200]) raceOverDelay(milliseconds);
	}

	/** A whole race over a delay: the browsers' results match the server's, and its corrections are measured and printed. */
	static function raceOverDelay(milliseconds:Int) {
		var harness = racingWith(milliseconds / 1000, 2);
		harness.runUntil(() -> harness.browsers[0].lastSnapshot?.state.phase == Finished, 600);
		var browser = harness.browsers[0];
		equal(browser.prediction.race.state.order.join(","), browser.lastSnapshot.state.order.join(","), 'the browser\'s finishing order against the server\'s at $milliseconds ms');
		equal(browser.lastSnapshot.state.phase, Finished, 'the server\'s race finished at $milliseconds ms');
		var corrections = harness.browsers[0].corrections.copy();
		corrections.sort(Reflect.compare);
		var share = (fraction:Float) -> corrections[Std.int(fraction * (corrections.length - 1))];
		say('    $milliseconds ms each way: corrections median ${metres(share(0.5))}, 95% under ${metres(share(0.95))}, biggest ${metres(share(1))}');
		isTrue(share(0.95) < 1.0, '95% of corrections under 1 m at $milliseconds ms, got ${metres(share(0.95))}');
	}

	static function metres(distance:Float):String {
		return '${Math.round(distance * 100) / 100} m';
	}

	/** A room with two browsers of one person each (the rest AI), racing on the oval over a delay. */
	static function racingWith(oneWaySeconds:Float, browsers:Int):OnlineHarness {
		var harness = new OnlineHarness(oneWaySeconds, false);
		for (index in 0...browsers) harness.arrive(["a", "b", "c", "d"][index], 1);
		harness.runUntil(() -> false, 0.5);
		harness.room.startRace("a");
		return harness;
	}
}
