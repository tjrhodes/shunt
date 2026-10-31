/** Runs every check of the simulation on Node: `haxe test.hxml` from the `sim` folder. */
class TestMain {
	static function main() {
		var everything = [DrivingTests.all, TrackTests.all, ContactTests.all, DamageTests.all, RaceTests.all, AiTests.all];
		Check.runAll(Lambda.flatten(everything));
	}
}
