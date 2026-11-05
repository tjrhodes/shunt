/** Runs the checks of the client's own logic (not its drawing) on Node: `haxe test.hxml` from the `client` folder. */
class ClientTestMain {
	static function main() {
		Check.runAll(LineupTests.all.concat(FlickTests.all));
	}
}
