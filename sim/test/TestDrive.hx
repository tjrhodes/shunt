import shunt.car.Car;
import shunt.car.CarInput;
import shunt.car.Driving;
import shunt.car.Ground;
import shunt.maths.Vector;

/**
 * A car on an empty car park, for trying things out: drive it with an input
 * for a while, or until something happens, and see where it got to.
 */
class TestDrive {
	public final car:Car;

	/** What it drives on: clean tarmac unless a test puts oil down. */
	public var ground:Ground = Grounds.cleanTarmac;

	/** Ticks driven so far: counted whole, so every drive of the same length is the same number of ticks. */
	var ticks = 0;

	/** Seconds driven so far. */
	public var time(get, never):Float;

	function get_time():Float {
		return ticks * Tick.seconds;
	}

	public function new(?car:Car) {
		this.car = car != null ? car : Cars.parkedAt(Vector.nothing(), 0);
	}

	/** Drives with the same input for a number of seconds. */
	public function hold(input:CarInput, seconds:Float):TestDrive {
		return driveUntil(_ -> input, _ -> false, seconds);
	}

	/** Drives with the same input until `isDone` says so, or until `atMost` seconds have gone by. */
	public function holdUntil(input:CarInput, isDone:Car -> Bool, atMost:Float):TestDrive {
		return driveUntil(_ -> input, isDone, atMost);
	}

	/** Drives with an input that changes over time (given the seconds driven so far). */
	public function follow(inputAt:Float -> CarInput, seconds:Float):TestDrive {
		return driveUntil(inputAt, _ -> false, seconds);
	}

	/** The one loop behind all three. Returns itself, so drives can be chained. */
	function driveUntil(inputAt:Float -> CarInput, isDone:Car -> Bool, atMost:Float):TestDrive {
		var lastTick = ticks + Math.round(atMost * Tick.perSecond);
		while (ticks < lastTick && !isDone(car)) {
			Driving.driveOneTick(car, inputAt(time), ground);
			ticks++;
		}
		return this;
	}

	/** An input, written briefly. */
	public static function pedals(throttle:Float, brake:Float, steer:Float):CarInput {
		return {throttle: throttle, brake: brake, steer: steer, recover: false};
	}
}
