package view.effects;

import shunt.maths.Vector;
import three.Three;

/**
 * Rubber left on the track by sliding tyres: short dark marks laid down
 * behind each sliding rear wheel, a few tenths of a metre apart. There is
 * room for so many; then the oldest is laid again somewhere new.
 */
class SkidMarks {
	static inline final most = 1600;
	static inline final markLength = 0.9;
	static inline final markWidth = 0.45;

	/** A wheel lays a new mark once it has moved this far (metres) from its last one. */
	static inline final spacing = 0.6;

	/** Marks sit a hair above the track, so they don't flicker into it. */
	static inline final aboveTheTrack = 0.03;

	public final mesh:InstancedMesh;
	final placer = new Object3D();
	final lastMarkByWheel = new Map<String, Vector>();
	var next = 0;

	public function new() {
		var flat = new PlaneGeometry(markLength, markWidth).rotateX(-Math.PI / 2);
		mesh = new InstancedMesh(flat, new MeshBasicMaterial({color: Paint.rubber, transparent: true, opacity: 0.75, depthWrite: false}), most);
		clear();
	}

	/** A wheel (named, so its marks join up) sliding at a spot, heading a way: lays a mark if it has moved on enough. */
	public function wheelSlidingAt(wheel:String, spot:Vector, heading:Float) {
		var last = lastMarkByWheel.get(wheel);
		if (last != null && last.distanceTo(spot) < spacing) return;
		lastMarkByWheel.set(wheel, spot);
		Placing.put(placer, spot, aboveTheTrack, heading);
		placer.scale.set(1, 1, 1);
		placer.updateMatrix();
		mesh.setMatrixAt(next, placer.matrix);
		mesh.instanceMatrix.needsUpdate = true;
		next = (next + 1) % most;
	}

	/** A wheel that has stopped sliding: its next mark starts a new streak. */
	public function wheelGripping(wheel:String) {
		lastMarkByWheel.remove(wheel);
	}

	/** A clean track (a new race). */
	public function clear() {
		placer.scale.set(0, 0, 0);
		placer.updateMatrix();
		for (index in 0...most) mesh.setMatrixAt(index, placer.matrix);
		mesh.instanceMatrix.needsUpdate = true;
		lastMarkByWheel.clear();
	}
}
