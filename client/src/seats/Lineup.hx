package seats;

import input.Controller;

using input.Controller.Controllers;

/**
 * Who is in each seat of the race: a person on a controller, or an AI
 * driver (SPEC.md §9, phase 2).
 *
 * Until anyone joins, it is the phase 1 game: the first seat is one person
 * driving with everything there is, and AI drivers take the rest. Once
 * someone joins (by pressing go on a keyboard half or a gamepad), seats are
 * claimed one controller each, in order, and the empty ones go to AI.
 * Pressing brake leaves a seat again.
 */
class Lineup {
	/** Each seat's controller, or nothing for an AI driver. */
	final claimed:Array<Null<Controller>>;

	public function new(seats:Int) {
		claimed = [for (_ in 0...seats) null];
	}

	/** How many seats there are in all. */
	public var seats(get, never):Int;

	function get_seats():Int {
		return claimed.length;
	}

	/** True once anyone has joined: then seats are one controller each. */
	public function anyoneJoined():Bool {
		return Lambda.exists(claimed, controller -> controller != null);
	}

	/** A controller takes the first empty seat, unless it already has one (or can't, or every seat is taken). True if anything changed. */
	public function join(controller:Controller):Bool {
		if (!controller.canClaimASeat() || seatOf(controller) >= 0) return false;
		var emptySeat = claimed.indexOf(null);
		if (emptySeat < 0) return false;
		claimed[emptySeat] = controller;
		return true;
	}

	/** A controller gives up its seat to an AI driver. True if it had one. */
	public function leave(controller:Controller):Bool {
		var seat = seatOf(controller);
		if (seat < 0) return false;
		claimed[seat] = null;
		return true;
	}

	/** Whether a person drives this seat (the first seat always does until anyone joins). */
	public function isHuman(seat:Int):Bool {
		return anyoneJoined() ? claimed[seat] != null : seat == 0;
	}

	/** The seats people drive, in order. */
	public function humanSeats():Array<Int> {
		return [for (seat in 0...seats) if (isHuman(seat)) seat];
	}

	/** How many people are racing. */
	public function people():Int {
		return humanSeats().length;
	}

	/** What drives a seat, out of every controller there is: one claimed controller, or (before anyone joins) all of them for the first seat; none for an AI seat. */
	public function controllersFor(seat:Int, every:Array<Controller>):Array<Controller> {
		if (!anyoneJoined()) return seat == 0 ? every : [];
		return claimed[seat] == null ? [] : [claimed[seat]];
	}

	/** The seat a controller has claimed, or -1. */
	public function seatOf(controller:Controller):Int {
		for (seat in 0...seats) if (claimed[seat] != null && claimed[seat].same(controller)) return seat;
		return -1;
	}

	/** The controller that claimed a seat, if any. */
	public function controllerIn(seat:Int):Null<Controller> {
		return claimed[seat];
	}
}
