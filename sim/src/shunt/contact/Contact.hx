package shunt.contact;

import shunt.maths.Vector;

/**
 * Two things touching: where, which way to push the first one to part them
 * (an arrow one long), and how far they overlap.
 */
typedef Contact = {
	final point:Vector;
	final pushFirstAway:Vector;
	final overlap:Float;
}
