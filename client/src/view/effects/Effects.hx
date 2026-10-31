package view.effects;

import feel.Slide;
import shunt.car.Car;
import shunt.car.CarTuning;
import shunt.car.Damage;
import shunt.car.DamageTuning;
import shunt.maths.Vector;
import shunt.race.Race;
import shunt.race.RaceEvent;
import three.Three;
import view.Placing.Point3;

using shunt.car.CarFrame;

/**
 * Everything that shows how hard the cars are being driven (SPEC.md §10):
 * skid marks and tyre smoke from sliding, sparks from hits, steam from a
 * bent front and smoke from a wreck. All read from the simulation after
 * each tick; none of it changes the race.
 */
class Effects {
	/** A hit that changes a car's speed by less than this (m/s) makes no sparks. */
	static inline final hitsSparkFrom = 2.0;

	/** In an all-out slide, each rear wheel puffs smoke on this share of ticks. */
	static inline final tyreSmokeEachTick = 0.35;

	/** At the worst damage, a car puffs steam or smoke on this share of ticks. */
	static inline final damageSmokeEachTick = 0.2;

	public final whole = new Group();
	final skids = new SkidMarks();
	final sparks = new ParticlePool({shape: new BoxGeometry(0.14, 0.14, 0.14), material: new MeshBasicMaterial({color: 0xffffff}), most: 300, gravity: 16, drag: 1.2});
	final puffs = new ParticlePool({shape: new BoxGeometry(1, 1, 1), material: new MeshLambertMaterial({color: 0xffffff}), most: 360, gravity: -1.5, drag: 2.5});

	public function new() {
		for (part in [skids.mesh, sparks.mesh, puffs.mesh]) whole.add(part);
	}

	/** What the last tick of a race leaves behind: marks and smoke from every car, sparks from every hit. */
	public function afterTick(race:Race) {
		for (number in 0...race.state.racers.length) {
			tyresOf(race.racer(number).car, number);
			damageSmokeFrom(race.racer(number).car);
		}
		for (event in race.events) if (event.kind == CarHit || event.kind == WallHit) showerOfSparks(event);
	}

	/** Moves every spark and puff on by some seconds. */
	public function animate(seconds:Float) {
		sparks.animate(seconds);
		puffs.animate(seconds);
	}

	/** A clean track for a new race. */
	public function clear() {
		skids.clear();
		sparks.clear();
		puffs.clear();
	}

	/** Each rear wheel of a sliding car lays rubber and, in a hard slide, smoke. */
	function tyresOf(car:Car, number:Int) {
		var slide = Slide.strength(car);
		for (side in [1, -1]) {
			var wheel = '$number$side';
			var spot = car.spotUnder(new Vector(-CarTuning.rearAxleBehind, side * CarTuning.width * 0.4));
			if (slide <= 0) skids.wheelGripping(wheel); else skids.wheelSlidingAt(wheel, spot, car.heading);
			if (Math.random() < slide * tyreSmokeEachTick) puff(spot, 0.3, Paint.tyreSmoke, 0.5, 1.6);
		}
	}

	/** Steam from a bent front (from the damage that starts to pull the steering), smoke from a car leaking oil. */
	function damageSmokeFrom(car:Car) {
		var bentFront = Damage.shareOfTheWayAbove(car.damage.front, DamageTuning.steeringPullsFrom);
		if (Math.random() < bentFront * damageSmokeEachTick) puff(car.spotUnder(new Vector(CarTuning.length / 2 - 0.4, 0)), 0.9, Paint.steam, 0.35, 1.2);
		if (Damage.isLeakingOil(car) && Math.random() < damageSmokeEachTick) puff(car.position, 1.2, Paint.engineSmoke, 0.5, 1.8);
	}

	/** A puff rising from a spot, drifting a little, growing as it fades. */
	function puff(spot:Vector, height:Float, colour:Int, startSize:Float, endSize:Float) {
		var drift:Point3 = {x: (Math.random() - 0.5) * 1.5, y: 1 + Math.random(), z: (Math.random() - 0.5) * 1.5};
		puffs.spawn(Placing.above(spot, height), drift, 0.9 + Math.random() * 0.6, startSize, endSize, colour);
	}

	/** A shower of sparks from the point of a hit: more, and faster, the harder it was. */
	function showerOfSparks(hit:RaceEvent) {
		if (hit.strength < hitsSparkFrom) return;
		var count = Std.int(Math.min(30, hit.strength * 2));
		for (_ in 0...count) {
			var direction = Vector.pointingAt(Math.random() * 2 * Math.PI) * (3 + Math.random() * hit.strength * 0.8);
			var flying:Point3 = {x: direction.x, y: 2 + Math.random() * 5, z: -direction.y};
			var colour = Paint.sparks[Std.random(Paint.sparks.length)];
			sparks.spawn(Placing.above(hit.point, 0.5), flying, 0.25 + Math.random() * 0.35, 1, 0.2, colour);
		}
	}
}
