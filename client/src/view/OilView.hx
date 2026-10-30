package view;

import shunt.car.DamageTuning;
import shunt.race.OilSpill;
import shunt.race.RaceState.OilPatch;
import three.Three;

/**
 * Oil patches on the track: dark, glossy discs the size the simulation uses,
 * fading as the oil dries. A few discs are made once and reused, one per
 * patch the track can hold.
 */
class OilView {
	static inline final howDarkWhenFresh = 0.85;

	public final whole = new Group();
	final discs:Array<Mesh>;

	public function new() {
		discs = [for (_ in 0...DamageTuning.mostOilPatches) oilDisc()];
		for (disc in discs) whole.add(disc);
	}

	/** Shows each patch on a disc; spare discs are hidden. */
	public function show(patches:Array<OilPatch>) {
		for (index in 0...discs.length) {
			var disc = discs[index];
			disc.visible = index < patches.length;
			if (!disc.visible) continue;
			Placing.put(disc, patches[index].position, 0.04, 0);
			disc.material.opacity = howDarkWhenFresh * OilSpill.freshness(patches[index]);
		}
	}

	static function oilDisc():Mesh {
		var look = new MeshBasicMaterial({color: Paint.oil, transparent: true, opacity: howDarkWhenFresh, depthWrite: false});
		var disc = new Mesh(new CircleGeometry(DamageTuning.oilPatchRadius, 24).rotateX(-Math.PI / 2), look);
		disc.visible = false;
		return disc;
	}
}
