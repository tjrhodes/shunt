import Check.*;
import input.SteeringRamp;
import shunt.maths.Numbers.wrapAngle;
import shunt.maths.Vector;
import shunt.Tick;

using shunt.car.CarFrame;

/**
 * The flick on keys (Tom, 1 Nov: it worked in the checks but not on the
 * keyboard). These drive the car through the very steering build-up the
 * keyboard uses, at its own pace, rather than with ready-made steering.
 */
class FlickTests {
	public static final all = [
		test("on keys, a tap right then hard left throws the tail out well beyond turning left off a straight", keyboardFlick),
		test("switching straight from one key to the other keeps the steering built up", switchingKeepsTheBuildUp)
	];

	static function keyboardFlick() {
		var fromStraight = biggestSlideOnKeys(0);
		var afterAFlick = biggestSlideOnKeys(0.3);
		say('    on keys at 30 m/s: left off a straight slides ${Math.round(fromStraight)}°, after a tap right ${Math.round(afterAFlick)}°');
		isTrue(afterAFlick >= 1.8 * fromStraight, 'slide after a flick on keys ${Math.round(afterAFlick)}°, from straight ${Math.round(fromStraight)}°');
		isTrue(afterAFlick < 50, 'not a spin: ${Math.round(afterAFlick)}°');
	}

	static function switchingKeepsTheBuildUp() {
		var ramp = new SteeringRamp();
		ramp.steering(1, 0);
		var builtRight = ramp.steering(1, 0.4);
		ramp.steering(0, 0.45);
		equal(Math.abs(ramp.steering(-1, 0.5)) >= builtRight, true, "left straight after right starts as strong as the right had got");
		ramp.steering(0, 0.6);
		equal(Math.abs(ramp.steering(-1, 2.0)), 0.3, "after a long rest it starts gentle again");
	}

	/** At 30 m/s on keys: right held for some seconds, then (after a moment's gap, as fingers do) left held; the biggest slide, in degrees. */
	static function biggestSlideOnKeys(rightFor:Float):Float {
		var drive = new TestDrive();
		drive.car.velocity = new Vector(30, 0);
		var ramp = new SteeringRamp();
		var biggest = 0.0;
		for (tick in 0...Tick.ticksIn(rightFor + 1.6)) {
			var now = tick * Tick.seconds;
			var way = now < rightFor ? 1 : (now < rightFor + 0.05 ? 0 : -1);
			drive.hold(TestDrive.pedals(0.6, 0, ramp.steering(way, now)), Tick.seconds);
			if (now > rightFor) biggest = Math.max(biggest, Math.abs(wrapAngle(drive.car.velocity.angle() - drive.car.heading)) * 180 / Math.PI);
		}
		return biggest;
	}
}
