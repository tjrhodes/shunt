import Check.*;
import TestRaces.oval;
import TestRaces.ovalLine;
import shunt.maths.Vector;
import shunt.race.RaceTuning;
import shunt.track.Track;
import shunt.track.Wall.Walls;

/** The track: is the oval the shape the spec says, and are its walls where its width says? (SPEC.md §5) */
class TrackTests {
	public static final all:Array<Check.Test> = [
		test("the oval is about 400 m round, sampled every metre", isAQuarterMile),
		test("the edge walls are half the track's width from the centreline", wallsAreWhereTheWidthSays),
		test("free-standing barriers become walls too", barriersAreWalls),
		test("joints in a smooth wall don't stick out; barrier tips and sharp corners do", onlyRealEndsStickOut),
		test("the grid is behind the line, each car further back, inside the walls", gridIsBehindTheLine),
		test("the racing line is slower in the bends than on the straights", bendsAreSlower)
	];

	static function isAQuarterMile() {
		between(oval.length, 395, 405, "metres round");
		var gaps = [for (index in 0...oval.samples.length) oval.sample(index).position.distanceTo(oval.sample(index + 1).position)];
		between(Lambda.fold(gaps, Math.min, 99.0), 0.95, 1.05, "shortest gap between samples");
		between(Lambda.fold(gaps, Math.max, 0.0), 0.95, 1.05, "longest gap between samples");
	}

	static function wallsAreWhereTheWidthSays() {
		for (index in [0, 50, 100, 150, 200, 300]) {
			var centre = oval.sample(index).position;
			var nearestWall = Lambda.fold(oval.walls, (wall, nearest) -> Math.min(nearest, Walls.nearestPointTo(wall, centre).distanceTo(centre)), 99.0);
			between(nearestWall, oval.sample(index).width / 2 - 0.1, oval.sample(index).width / 2 + 0.1, 'nearest wall from sample $index');
		}
	}

	static function barriersAreWalls() {
		var withAnL = new Track({
			name: "Oval with an L",
			centreline: [for (point in oval.samples) if (Math.round(point.distance) % 20 == 0) {x: point.position.x, y: point.position.y, width: point.width}],
			barriers: [[{x: 0, y: 0}, {x: 10, y: 0}, {x: 10, y: 5}]]
		});
		equal(withAnL.walls.length - oval.walls.length, 2, "extra walls from a barrier with three corners");
		isTrue(withAnL.wallsNear(new Vector(5, 1), 2).length > 0, "the barrier is found near its middle");
	}

	/** A joint that stuck out stopped cars dead against the oval's walls (Tom's third drive). */
	static function onlyRealEndsStickOut() {
		var stickingOutOfTheOval = Lambda.fold(oval.walls, (wall, count) -> count + wall.endsThatStickOut.length, 0);
		equal(stickingOutOfTheOval, 0, "ends sticking out of the oval's smooth walls");
		var anL = Walls.joining([new Vector(0, 0), new Vector(10, 0), new Vector(10, 5)], false);
		equal(anL[0].endsThatStickOut.length + anL[1].endsThatStickOut.length, 4, "an L's tips and its bend (counted on both pieces)");
	}

	static function gridIsBehindTheLine() {
		var race = TestRaces.newRace(4, 1);
		var lastIndex = oval.samples.length;
		for (racer in race.state.racers) {
			isTrue(racer.trackIndex < lastIndex && racer.trackIndex > oval.samples.length / 2, 'a car further back, at sample ${racer.trackIndex}');
			between(Math.abs(oval.howFarLeft(racer.car.position, racer.trackIndex)), 0, oval.sample(racer.trackIndex).width / 2 - 1, "metres from the centreline");
			lastIndex = racer.trackIndex;
		}
		equal(race.state.racers[0].nextCheckpoint, RaceTuning.checkpoints, "the line is next");
	}

	static function bendsAreSlower() {
		var sharpest = 0;
		for (index in 0...oval.samples.length) if (oval.sample(index).bendiness > oval.sample(sharpest).bendiness) sharpest = index;
		isTrue(ovalLine.speedAt(sharpest) < 0.6 * ovalLine.speedAt(0), 'bend ${ovalLine.speedAt(sharpest)} m/s, start line ${ovalLine.speedAt(0)} m/s');
	}
}
