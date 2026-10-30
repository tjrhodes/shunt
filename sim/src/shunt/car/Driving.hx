package shunt.car;

import shunt.car.CarInput.CarInputs;

using shunt.car.Controls;
using shunt.car.Tyres;
using shunt.car.Engine;
using shunt.car.CarMotion;

/**
 * One tick of one car on open ground: the whole story of how a car drives,
 * in order. Walls and other cars come in later, in the race (SPEC.md §4).
 */
class Driving {
	public static function driveOneTick(car:Car, input:CarInput, ground:Ground) {
		var tidyInput = CarInputs.tidied(input);
		car.followTheDriver(tidyInput);
		var allThePushes = car.grip(ground).plus(car.engineBrakesAndAir(tidyInput));
		car.moveOneTick(allThePushes);
	}
}
