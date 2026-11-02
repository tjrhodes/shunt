package view;

/** A car's look: its colour and the number on its roof. */
typedef Livery = {
	final colour:Int;
	final number:Int;
}

/**
 * Every colour in the game, in one place: the 3D scene and the HUD both read
 * them from here (the page's stylesheet gets the player's colour from here
 * too, at start-up). The palette is the portfolio site's, from Tom's photo
 * of Norwegian rock and lichen (2 Nov): night-blue rock for the ground and
 * sky, pale stone for walls and roofs, and lichen yellows, oranges and rust
 * for the cars, the barriers and the crowd.
 */
class Paint {
	public static inline final sky = 0x151a2b;
	public static inline final grass = 0x1b2848;
	public static inline final asphalt = 0x293046;
	public static inline final concrete = 0xdbd2b9;
	public static inline final startLine = 0xf6f2e8;
	public static inline final chequerDark = 0x151a2b;
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
	public static inline final barrierStripe = 0xd9730f;
	public static inline final leaves = 0x2a3f3a;
	public static inline final trunk = 0x633311;
	public static inline final standConcrete = 0x465d8c;
	public static inline final towerSteel = 0x6983b6;
	public static inline final billboardWords = 0xffffff;

	/** Each sponsor's board colour, in turn (their names are in hud/Words.hx). */
	public static final billboards = [0xd9730f, 0x3a5382, 0x151a2b, 0xd9a21b, 0xc54b12];

	/** The crowd's shirts. */
	public static final crowd = [0xf6f2e8, 0xe9c93a, 0xd9730f, 0x6983b6, 0xc54b12, 0xdbd2b9, 0x151a2b];

	// ---- Car details ----
	public static inline final roof = 0xf6f2e8;
	public static inline final chrome = 0xc9ced4;
	public static inline final wheelArch = 0x1a1c20;
	public static inline final headlight = 0xfff6d8;
	public static inline final tailLight = 0xd8281e;

	/** Floodlight from above, and the glow of the infield below. */
	public static inline final floodlight = 0xfff4e0;
	public static inline final skyGlow = 0x8fa3c8;
	public static inline final groundGlow = 0x293b5f;

	/** One livery per seat; the first is always the player's. */
	public static final liveries:Array<Livery> = [
		{colour: 0xe9c93a, number: 7},
		{colour: 0x6983b6, number: 12},
		{colour: 0xc54b12, number: 33},
		{colour: 0xdbd2b9, number: 51}
	];

	/** A colour as CSS writes it ("#f2b134"). */
	public static function css(colour:Int):String {
		return "#" + StringTools.hex(colour, 6);
	}
}
