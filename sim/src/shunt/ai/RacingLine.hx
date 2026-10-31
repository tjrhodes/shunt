package shunt.ai;

import shunt.ai.AiTuning as Ai;
import shunt.car.CarTuning;
import shunt.track.Track;

/**
 * How fast each bit of a track can safely be driven: slow enough in the
 * bends for the tyres to hold, and slow enough before them to brake in time.
 * Worked out once per track from its centreline, so any layout works
 * (SPEC.md §5, §7).
 */
class RacingLine {
	/** The fastest safe speed at each centreline sample, in m/s. */
	public final speeds:Array<Float>;

	public function new(track:Track) {
		speeds = [for (sample in track.samples) speedForBend(sample.bendiness)];
		brakeInTime(speeds, track.length / track.samples.length);
	}

	/** The safe speed at a sample, counting round the loop. */
	public function speedAt(index:Int):Float {
		return speeds[((index % speeds.length) + speeds.length) % speeds.length];
	}

	/**
	 * The fastest a car can take a bend: the tyres must supply the push that
	 * turns it, speed squared over the bend's radius, so speed is the square
	 * root of grip times radius. Never more than top speed.
	 */
	static function speedForBend(bendiness:Float):Float {
		var weakerGrip = Math.min(CarTuning.frontGrip, CarTuning.rearGrip) * CarTuning.gravity * Ai.shareOfGripInBends;
		if (bendiness <= 0) return CarTuning.topSpeed;
		return Math.min(CarTuning.topSpeed, Math.sqrt(weakerGrip / bendiness));
	}

	/**
	 * Working backwards from every slow bit, lowers the speed before it to
	 * what can be braked away in the distance. Twice round, so the braking
	 * for a bend near the start line reaches back past the end of the lap.
	 */
	static function brakeInTime(speeds:Array<Float>, spacing:Float) {
		var braking = CarTuning.brakeForce / CarTuning.mass * Ai.shareOfBrakesPlanned;
		var count = speeds.length;
		for (step in 1...2 * count + 1) {
			var index = (2 * count - step) % count;
			var nextSpeed = speeds[(index + 1) % count];
			speeds[index] = Math.min(speeds[index], Math.sqrt(nextSpeed * nextSpeed + 2 * braking * spacing));
		}
	}
}
