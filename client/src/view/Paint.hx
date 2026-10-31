package view;

/** A car's look: its colour and the number on its roof. */
typedef Livery = {
	final colour:Int;
	final number:Int;
}

/**
 * Every colour in the game, in one place: the 3D scene and the HUD both read
 * them from here (the page's stylesheet gets the player's colour from here
 * too, at start-up). Night race under lights: dark asphalt, worn concrete,
 * and bright cars.
 */
class Paint {
	public static inline final sky = 0x101318;
	public static inline final grass = 0x1d2a22;
	public static inline final asphalt = 0x30343b;
	public static inline final concrete = 0xc9c4b6;
	public static inline final startLine = 0xf1efe8;
	public static inline final chequerDark = 0x15171b;
	public static inline final oil = 0x050607;
	public static inline final tyre = 0x141414;
	public static inline final glass = 0x1b2530;
	public static inline final roofNumber = 0x111111;
	public static inline final roofDisc = 0xf4f2ec;

	// ---- Effects ----
	public static inline final rubber = 0x0b0b0c;
	public static inline final tyreSmoke = 0xc8ccd2;
	public static inline final steam = 0xf3f5f7;
	public static inline final engineSmoke = 0x2b2b2d;
	public static final sparks = [0xfff1b8, 0xffd36b, 0xff9a3c];

	// ---- Round the track ----
	public static inline final barrierStripe = 0xc8402f;
	public static inline final leaves = 0x24402c;
	public static inline final trunk = 0x3a2b20;
	public static inline final standConcrete = 0x5d6068;
	public static inline final towerSteel = 0x6e737c;
	public static inline final billboardWords = 0xffffff;

	/** Each sponsor's board colour, in turn (their names are in hud/Words.hx). */
	public static final billboards = [0xc8402f, 0x2f6fc8, 0x1d1f24, 0xe0a022, 0x3f9a5c];

	/** The crowd's shirts. */
	public static final crowd = [0xe8e4da, 0xc8402f, 0x2f6fc8, 0xf2b134, 0x3f9a5c, 0x8a5bb5, 0x23262c];

	// ---- Car details ----
	public static inline final spoiler = 0x16181c;
	public static inline final headlight = 0xfff6d8;
	public static inline final tailLight = 0xd8281e;

	/** Floodlight from above, and the glow of the infield below. */
	public static inline final floodlight = 0xfff4e0;
	public static inline final skyGlow = 0x8fa3c0;
	public static inline final groundGlow = 0x23302a;

	/** One livery per seat; the first is always the player's. */
	public static final liveries:Array<Livery> = [
		{colour: 0xf2b134, number: 7},
		{colour: 0x3f8fd8, number: 12},
		{colour: 0xd8543f, number: 33},
		{colour: 0x55b47a, number: 51}
	];

	/** A colour as CSS writes it ("#f2b134"). */
	public static function css(colour:Int):String {
		return "#" + StringTools.hex(colour, 6);
	}
}
