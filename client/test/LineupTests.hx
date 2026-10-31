import Check.*;
import input.Controller;
import seats.Lineup;

/** Who sits where (SPEC.md §9, phase 2): joining, leaving, and the solo game before anyone joins. */
class LineupTests {
	public static final all = [
		test("before anyone joins, the first seat drives with everything and the rest are AI", () -> {
			var lineup = new Lineup(4);
			var every = [KeyboardLeft, KeyboardRight, Touch, Pad(0)];
			equal(lineup.controllersFor(0, every).length, 4, "controllers for the first seat");
			equal(lineup.controllersFor(1, every).length, 0, "controllers for the second seat");
			equal(lineup.people(), 1, "people racing");
		}),
		test("people take the seats in the order they join, one controller each", () -> {
			var lineup = new Lineup(4);
			isTrue(lineup.join(Pad(2)), "a pad joins");
			isTrue(lineup.join(KeyboardRight), "the arrows join");
			equal(lineup.seatOf(Pad(2)), 0, "the pad's seat");
			equal(lineup.seatOf(KeyboardRight), 1, "the arrows' seat");
			equal(lineup.controllersFor(0, [KeyboardLeft, KeyboardRight, Pad(2)]).length, 1, "the pad drives its seat alone");
			equal(lineup.people(), 2, "people racing");
			isTrue(!lineup.isHuman(2), "the third seat is an AI driver");
		}),
		test("joining twice, joining by touch, or joining a full race changes nothing", () -> {
			var lineup = new Lineup(2);
			lineup.join(KeyboardLeft);
			isTrue(!lineup.join(KeyboardLeft), "the same keys again");
			isTrue(!lineup.join(Touch), "touch");
			lineup.join(Pad(0));
			isTrue(!lineup.join(Pad(1)), "a third player with two seats");
		}),
		test("leaving hands the seat to an AI driver, and the next to join takes it", () -> {
			var lineup = new Lineup(4);
			lineup.join(KeyboardLeft);
			lineup.join(KeyboardRight);
			isTrue(lineup.leave(KeyboardLeft), "the left keys leave");
			isTrue(!lineup.isHuman(0), "the first seat is AI again");
			lineup.join(Pad(1));
			equal(lineup.seatOf(Pad(1)), 0, "the pad takes the empty first seat");
		}),
		test("when everyone leaves, it is the solo game again", () -> {
			var lineup = new Lineup(4);
			lineup.join(Pad(0));
			lineup.leave(Pad(0));
			isTrue(!lineup.anyoneJoined(), "nobody has joined");
			isTrue(lineup.isHuman(0), "the first seat is a person again");
		})
	];
}
