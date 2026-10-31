package shunt.online;

import shunt.online.Messages.SeatHolder;

/** A browser in a room, and how many people it brought. */
typedef Browser = {
	final session:String;
	var people:Int;
}

/**
 * Who is in an online room and who sits where (SPEC.md §9).
 *
 * Browsers are kept in the order they arrived. Seats are handed out in
 * that order too, one per person, so whoever came first is sure of a
 * place; anyone left over watches until a seat comes free. Seats are only
 * shuffled between races: if someone leaves during one, an AI driver takes
 * over their car until the end.
 */
class RoomSeats {
	/** Every browser in the room, first to arrive first. */
	public final browsers:Array<Browser> = [];

	/** Who sits in each seat now; an empty owner is an AI driver. */
	public final seats:Array<SeatHolder> = [for (_ in 0...OnlineTuning.seats) aiDriver()];

	public function new() {}

	/** An empty seat: an AI driver's. */
	public static function aiDriver():SeatHolder {
		return {owner: "", person: 0};
	}

	/** A browser has come in; until it says how many people it brings, it just watches. */
	public function arrive(session:String) {
		browsers.push({session: session, people: 0});
	}

	/** A browser says how many people it brings (kept between 0 and the most one browser can bring). */
	public function want(session:String, people:Int) {
		var browser = browserOf(session);
		if (browser != null) browser.people = Std.int(Math.max(0, Math.min(OnlineTuning.mostPeoplePerBrowser, people)));
	}

	/** A browser has gone: it leaves the room, and AI drivers take its seats. */
	public function depart(session:String) {
		browsers.remove(browserOf(session));
		for (seat in 0...seats.length) if (seats[seat].owner == session) seats[seat] = aiDriver();
	}

	/** Hands out the seats afresh (between races): browser by browser in the order they came, a seat per person, AI drivers in the rest. */
	public function seatEveryone() {
		var people:Array<SeatHolder> = [for (browser in browsers) for (person in 0...browser.people) {owner: browser.session, person: person}];
		for (seat in 0...seats.length) seats[seat] = seat < people.length ? people[seat] : aiDriver();
	}

	/** The browser that runs the room: whichever has been in longest. */
	public function host():String {
		return browsers.length > 0 ? browsers[0].session : "";
	}

	/** How many seats people sit in. */
	public function peopleSeated():Int {
		return Lambda.count(seats, seat -> seat.owner != "");
	}

	/** How many people the browsers say they bring, seated or not. */
	public function peopleHere():Int {
		return Lambda.fold(browsers, (browser, total) -> total + browser.people, 0);
	}

	function browserOf(session:String):Null<Browser> {
		return Lambda.find(browsers, browser -> browser.session == session);
	}
}
