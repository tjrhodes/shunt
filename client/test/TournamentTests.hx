import Check.*;
import tournament.Tournament;

/** Tournaments (Tom, 4 Nov): the tracks picked, swapped and resized, points scored, and the standings. */
class TournamentTests {
	/** A "random" pick that just counts up, so the checks always see the same tracks. */
	static function counting():Int -> Int {
		var count = 0;
		return below -> count++ % below;
	}

	public static final all = [
		test("a tournament picks as many different tracks as it has races", () -> {
			var tournament = new Tournament(16, 10, 4, counting());
			equal(tournament.tracks.length, 10, "races");
			for (track in tournament.tracks) equal(Lambda.count(tournament.tracks, other -> other == track), 1, 'times track $track appears');
		}),
		test("making it longer keeps the tracks chosen and adds new ones; shorter drops the last", () -> {
			var tournament = new Tournament(16, 3, 4, counting());
			tournament.swap(1, 15);
			tournament.resize(5);
			equal(tournament.tracks[1], 15, "the swapped track stays");
			equal(tournament.tracks.length, 5, "races after making it longer");
			tournament.resize(3);
			equal(tournament.tracks.length, 3, "races after making it shorter");
			equal(tournament.tracks[1], 15, "still the swapped track");
		}),
		test("3 points for a win, 2 for second, 1 for third, none for fourth", () -> {
			var tournament = new Tournament(16, 3, 4, counting());
			tournament.score([2, 0, 3, 1]);
			tournament.score([0, 2, 1, 3]);
			equal(tournament.points.join(","), "5,1,5,1", "points by seat");
			equal(tournament.racesRun, 2, "races run");
			isTrue(!tournament.isOver(), "one race still to run");
			equal(tournament.nextTrack(), tournament.tracks[2], "the next race's track");
		}),
		test("a tie on points goes to whoever won more races", () -> {
			var tournament = new Tournament(16, 3, 4, counting());
			tournament.score([0, 1, 2, 3]);
			tournament.score([1, 2, 3, 0]);
			equal(tournament.points.join(","), "3,5,3,1", "points by seat");
			equal(tournament.standings().join(","), "1,0,2,3", "seats first to last (seat 0 and seat 2 both on 3, seat 0 with a win)");
		}),
		test("the tournament is over once every race is run", () -> {
			var tournament = new Tournament(16, 3, 4, counting());
			for (_ in 0...3) tournament.score([0, 1, 2, 3]);
			isTrue(tournament.isOver(), "all three run");
			equal(tournament.points[0], 9, "three wins");
		}),
		test("every race's seed keeps the same kind of AI driver in each seat", () -> {
			var tournament = new Tournament(16, 5, 4, counting());
			var first = tournament.seedForARace();
			for (_ in 0...10) equal(tournament.seedForARace() % 3, first % 3, "the seed's remainder by 3");
		}),
	];
}
