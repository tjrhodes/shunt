import Check.*;
import trophy.Trophy;

/** Trophies (Tom, 4 Nov): the tracks picked, swapped and resized, points scored, and the standings. */
class TrophyTests {
	/** A "random" pick that just counts up, so the checks always see the same tracks. */
	static function counting():Int -> Int {
		var count = 0;
		return below -> count++ % below;
	}

	public static final all = [
		test("a trophy picks as many different tracks as it has races", () -> {
			var trophy = new Trophy(16, 10, 4, counting());
			equal(trophy.tracks.length, 10, "races");
			for (track in trophy.tracks) equal(Lambda.count(trophy.tracks, other -> other == track), 1, 'times track $track appears');
		}),
		test("making it longer keeps the tracks chosen and adds new ones; shorter drops the last", () -> {
			var trophy = new Trophy(16, 3, 4, counting());
			trophy.swap(1, 15);
			trophy.resize(5);
			equal(trophy.tracks[1], 15, "the swapped track stays");
			equal(trophy.tracks.length, 5, "races after making it longer");
			trophy.resize(3);
			equal(trophy.tracks.length, 3, "races after making it shorter");
			equal(trophy.tracks[1], 15, "still the swapped track");
		}),
		test("3 points for a win, 2 for second, 1 for third, none for fourth", () -> {
			var trophy = new Trophy(16, 3, 4, counting());
			trophy.score([2, 0, 3, 1]);
			trophy.score([0, 2, 1, 3]);
			equal(trophy.points.join(","), "5,1,5,1", "points by seat");
			equal(trophy.racesRun, 2, "races run");
			isTrue(!trophy.isOver(), "one race still to run");
			equal(trophy.nextTrack(), trophy.tracks[2], "the next race's track");
		}),
		test("a tie on points goes to whoever won more races", () -> {
			var trophy = new Trophy(16, 3, 4, counting());
			trophy.score([0, 1, 2, 3]);
			trophy.score([1, 2, 3, 0]);
			equal(trophy.points.join(","), "3,5,3,1", "points by seat");
			equal(trophy.standings().join(","), "1,0,2,3", "seats first to last (seat 0 and seat 2 both on 3, seat 0 with a win)");
		}),
		test("the trophy is over once every race is run", () -> {
			var trophy = new Trophy(16, 3, 4, counting());
			for (_ in 0...3) trophy.score([0, 1, 2, 3]);
			isTrue(trophy.isOver(), "all three run");
			equal(trophy.points[0], 9, "three wins");
		}),
		test("every race's seed keeps the same kind of AI driver in each seat", () -> {
			var trophy = new Trophy(16, 5, 4, counting());
			var first = trophy.seedForARace();
			for (_ in 0...10) equal(trophy.seedForARace() % 3, first % 3, "the seed's remainder by 3");
		}),
	];
}
