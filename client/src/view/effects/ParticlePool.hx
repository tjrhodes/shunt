package view.effects;

import three.Three;
import view.Placing.Point3;

/** One particle: a spark or a puff of smoke, from its birth until it has lived its life. */
typedef Particle = {
	var x:Float;
	var y:Float;
	var z:Float;
	var vx:Float;
	var vy:Float;
	var vz:Float;
	var age:Float;
	var life:Float;
	var startSize:Float;
	var endSize:Float;
}

/** What a kind of particle looks like and how it moves. */
typedef ParticleLook = {
	final shape:BufferGeometry;
	final material:Material;
	final most:Int;

	/** Pull down (m/s²): positive for sparks, negative to make smoke rise. */
	final gravity:Float;

	/** The share of its speed a particle loses each second, to the air. */
	final drag:Float;
}

/**
 * A fixed number of particles, all drawn at once as one instanced mesh, so
 * a busy race costs no more than a quiet one. A new particle takes the
 * place of the oldest; one that has lived its life shrinks to nothing.
 */
class ParticlePool {
	public final mesh:InstancedMesh;
	final look:ParticleLook;
	final particles:Array<Particle>;
	final placer = new Object3D();
	final tint = new Color(0xffffff);
	var next = 0;

	public function new(look:ParticleLook) {
		this.look = look;
		mesh = new InstancedMesh(look.shape, look.material, look.most);
		particles = [for (_ in 0...look.most) {x: 0, y: 0, z: 0, vx: 0, vy: 0, vz: 0, age: 1, life: 1, startSize: 0, endSize: 0}];
		for (index in 0...look.most) mesh.setColorAt(index, tint);
		clear();
	}

	/** A new particle, in the place of the oldest, at a spot, moving, growing or shrinking over its life. */
	public function spawn(at:Point3, moving:Point3, life:Float, startSize:Float, endSize:Float, colour:Int) {
		var particle = particles[next];
		particle.x = at.x;
		particle.y = at.y;
		particle.z = at.z;
		particle.vx = moving.x;
		particle.vy = moving.y;
		particle.vz = moving.z;
		particle.age = 0;
		particle.life = life;
		particle.startSize = startSize;
		particle.endSize = endSize;
		mesh.setColorAt(next, tint.setHex(colour));
		next = (next + 1) % particles.length;
	}

	/** Moves every particle on by some seconds, and redraws them all. */
	public function animate(seconds:Float) {
		for (index in 0...particles.length) moveAndPlace(index, seconds);
		mesh.instanceMatrix.needsUpdate = true;
		if (mesh.instanceColor != null) mesh.instanceColor.needsUpdate = true;
	}

	/** Every particle gone at once (a new race). */
	public function clear() {
		for (particle in particles) particle.age = particle.life;
		animate(0);
	}

	/** One particle: older, pulled down (or up), slowed by the air, and drawn at its size for its age. */
	function moveAndPlace(index:Int, seconds:Float) {
		var particle = particles[index];
		particle.age = Math.min(particle.life, particle.age + seconds);
		var keep = Math.max(0, 1 - look.drag * seconds);
		particle.vx *= keep;
		particle.vz *= keep;
		particle.vy = particle.vy * keep - look.gravity * seconds;
		particle.x += particle.vx * seconds;
		particle.y = Math.max(0, particle.y + particle.vy * seconds);
		particle.z += particle.vz * seconds;
		place(index, particle);
	}

	/** Draws a particle at its place and size; at the end of its life its size is nothing, so it is gone. */
	function place(index:Int, particle:Particle) {
		var shareOfLife = particle.age / particle.life;
		var size = shareOfLife >= 1 ? 0 : particle.startSize + (particle.endSize - particle.startSize) * shareOfLife;
		placer.position.set(particle.x, particle.y, particle.z);
		placer.rotation.y = particle.age * 3;
		placer.scale.set(size, size, size);
		placer.updateMatrix();
		mesh.setMatrixAt(index, placer.matrix);
	}
}
