/** One named test. */
typedef Test = {
	final name:String;
	final body:() -> Void;
}

/**
 * A deliberately tiny test runner, as in bümbap: nothing to install, nothing
 * to learn. Tests run one after another; every failed check is printed with
 * the name of its test, and Node exits with code 1 if anything failed.
 */
class Check {
	static var passed = 0;
	static var failed = 0;
	static var currentTest = "";

	public static function test(name:String, body:() -> Void):Test {
		return {name: name, body: body};
	}

	public static function isTrue(condition:Bool, what:String) {
		if (condition) passed++; else fail(what);
	}

	public static function equal<T>(actual:T, expected:T, what:String) {
		isTrue(actual == expected, '$what: expected $expected, got $actual');
	}

	/** For measurements, which land in a range rather than on a number. */
	public static function between(actual:Float, lowest:Float, highest:Float, what:String) {
		isTrue(actual >= lowest && actual <= highest, '$what: expected $lowest to $highest, got $actual');
	}

	/** Runs every test in order, then prints the totals. */
	public static function runAll(tests:Array<Test>) {
		for (test in tests) runOne(test);
		say('$passed checks passed, $failed failed');
		if (failed > 0) js.Syntax.code("process.exitCode = 1");
	}

	/** A test that throws counts as one failure, and the rest still run. */
	static function runOne(test:Test) {
		currentTest = test.name;
		try {
			test.body();
		} catch (error:haxe.Exception) {
			fail('threw: ${error.message}');
		}
	}

	/** Prints a line on Node's console. */
	static function say(line:String) {
		js.Syntax.code("console.log({0})", line);
	}

	static function fail(message:String) {
		failed++;
		say('  ✗ $currentTest — $message');
	}
}
