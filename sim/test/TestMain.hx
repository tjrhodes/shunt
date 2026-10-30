/** Runs every check of the simulation on Node: `haxe test.hxml` from the `sim` folder. */
class TestMain {
	static function main() {
		Check.runAll(DrivingTests.all);
	}
}
