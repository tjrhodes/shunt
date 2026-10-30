package shunt.car;

import shunt.maths.Vector;

/**
 * What a car is driving on: how much grip the surface gives at each spot,
 * as a share of clean tarmac (1). The race makes one each tick that knows
 * where the oil is; a car on its own drives on clean tarmac.
 */
typedef Ground = {
	function gripAt(spot:Vector):Float;
}

class Grounds {
	/** Grip everywhere. */
	public static final cleanTarmac:Ground = {gripAt: _ -> 1.0};
}
