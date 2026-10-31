package shunt.track;

import shunt.maths.Numbers.partWay;
import shunt.maths.Vector;
import shunt.track.TrackFile.TrackPoint;

/** A place on the centreline and how wide the track is there. */
typedef CentrePlace = {
	final position:Vector;
	final width:Float;
}

/**
 * Turns the few points placed by hand into a smooth centreline, cut into
 * pieces exactly the same length all the way round.
 *
 * The curve is a Catmull-Rom spline: it passes through every hand-placed
 * point, and between two points it bends to line up with the points either
 * side, so the corners come out round.
 */
class Centreline {
	/** How many little steps the curve is first drawn with between two hand-placed points. */
	static inline final stepsBetweenPoints = 24;

	/** The smoothed centreline, closed, with places as close to `spacing` metres apart as divides the loop evenly. */
	public static function evenlySpaced(points:Array<TrackPoint>, spacing:Float):Array<CentrePlace> {
		var fineCurve = [for (index in 0...points.length * stepsBetweenPoints) curvePlace(points, index / stepsBetweenPoints)];
		return walkEvenly(fineCurve, spacing);
	}

	/**
	 * A place on the curve, `along` being how many hand-placed points in
	 * (2.5 is halfway between points 2 and 3). The width changes gently too.
	 */
	static function curvePlace(points:Array<TrackPoint>, along:Float):CentrePlace {
		var first = Math.floor(along);
		var point = offset -> points[(first + offset + points.length) % points.length];
		var shareOfTheWay = along - first;
		var position = catmullRom(spotOf(point(-1)), spotOf(point(0)), spotOf(point(1)), spotOf(point(2)), shareOfTheWay);
		return {position: position, width: partWay(point(0).width, point(1).width, shareOfTheWay)};
	}

	/** The standard Catmull-Rom sum: a point part of the way from `here` to `next`, curving to suit the neighbours. */
	static function catmullRom(before:Vector, here:Vector, next:Vector, after:Vector, t:Float):Vector {
		var squared = t * t;
		var cubed = squared * t;
		var startsAt = here * 2;
		var leaning = (next - before) * t;
		var bending = (before * 2 - here * 5 + next * 4 - after) * squared;
		var settling = (here * 3 - before - next * 3 + after) * cubed;
		return (startsAt + leaning + bending + settling) * 0.5;
	}

	static function spotOf(point:TrackPoint):Vector {
		return new Vector(point.x, point.y);
	}

	/**
	 * Walks round the finely drawn curve, dropping a place every so many
	 * metres. The spacing is stretched a hair so the last piece ends exactly
	 * where the first began.
	 */
	static function walkEvenly(curve:Array<CentrePlace>, spacing:Float):Array<CentrePlace> {
		var distances = distancesRound(curve);
		var loopLength = distances[curve.length];
		var pieces = Math.round(loopLength / spacing);
		var piece = 0;
		return [for (index in 0...pieces) {
			var wanted = index * loopLength / pieces;
			while (distances[piece + 1] < wanted) piece++;
			placeBetween(curve, piece, (wanted - distances[piece]) / (distances[piece + 1] - distances[piece]));
		}];
	}

	/** How far round the curve each of its places is, plus the whole way round at the end. */
	static function distancesRound(curve:Array<CentrePlace>):Array<Float> {
		var distances = [0.0];
		for (index in 0...curve.length) {
			var gap = curve[index].position.distanceTo(curve[(index + 1) % curve.length].position);
			distances.push(distances[index] + gap);
		}
		return distances;
	}

	/** A place part of the way from one place on the curve to the next. */
	static function placeBetween(curve:Array<CentrePlace>, index:Int, shareOfTheWay:Float):CentrePlace {
		var here = curve[index];
		var next = curve[(index + 1) % curve.length];
		var position = here.position + (next.position - here.position) * shareOfTheWay;
		return {position: position, width: partWay(here.width, next.width, shareOfTheWay)};
	}
}
