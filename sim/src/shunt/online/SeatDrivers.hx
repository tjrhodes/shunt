package shunt.online;

import shunt.ai.AiDriver;
import shunt.ai.DriverCharacter;
import shunt.ai.RacingLine;
import shunt.online.Messages.SeatHolder;

/**
 * The AI drivers for the empty seats of an online race. The server and
 * every browser make them the same way from the same seed, and AI drivers
 * remember nothing between ticks, so a browser can predict them exactly.
 */
class SeatDrivers {
	/** An AI driver for each seat no person holds, nothing for the others. */
	public static function forSeats(seats:Array<SeatHolder>, seed:Int, line:RacingLine):Array<Null<AiDriver>> {
		return [for (seat in 0...seats.length) seats[seat].owner == "" ? new AiDriver(DriverCharacters.forSeat(seed, seat), line, seat) : null];
	}
}
