package view;

import js.Browser;
import js.html.CanvasElement;
import js.html.CanvasRenderingContext2D;

/** One spark of a burst: where it is, how it's moving, its colour, and how much life it has left (1 to 0). */
private typedef Spark = {
	var x:Float;
	var y:Float;
	var dx:Float;
	var dy:Float;
	final colour:String;
	var life:Float;
}

/**
 * Fireworks over the page when you win a tournament (Tom, 4 Nov): bursts
 * of sparks in the palette's colours, one after another for a few
 * seconds, falling and fading. Drawn on a canvas over everything that
 * doesn't catch clicks. Nothing at all for anyone who prefers less motion.
 */
class Fireworks {
	/** How long the show goes on (seconds), and how often a new burst goes up. */
	static inline final showLasts = 6.0;
	static inline final burstEvery = 0.45;

	/** Each burst: how many sparks, how fast they fly out (CSS pixels a second), how fast they fall, how long they live. */
	static inline final sparksInABurst = 70;
	static inline final burstSpeed = 260.0;
	static inline final gravity = 220.0;
	static inline final sparkLives = 1.3;

	static final colours = ["#e9c93a", "#e07f11", "#c54b12", "#f6f2e8", "#6983b6", "#d9a21b"];

	final canvas:CanvasElement;
	final paint:CanvasRenderingContext2D;
	final sparks:Array<Spark> = [];
	var showLeft = 0.0;
	var nextBurst = 0.0;

	public function new() {
		canvas = Browser.document.createCanvasElement();
		canvas.className = "fireworks";
		Browser.document.body.appendChild(canvas);
		paint = canvas.getContext2d();
	}

	/** The show starts (unless the viewer prefers less motion). */
	public function start() {
		if (Browser.window.matchMedia("(prefers-reduced-motion: reduce)").matches) return;
		showLeft = showLasts;
		nextBurst = 0;
	}

	/** The show stops at once (the panel it celebrated has gone). */
	public function stop() {
		showLeft = 0;
		sparks.resize(0);
		paint.clearRect(0, 0, canvas.width, canvas.height);
	}

	/** Moves the show on by some seconds: new bursts while it lasts, every spark flying, falling and fading. */
	public function animate(seconds:Float) {
		if (showLeft <= 0 && sparks.length == 0) return;
		fitTheScreen();
		showLeft -= seconds;
		nextBurst -= seconds;
		if (showLeft > 0 && nextBurst <= 0) burst();
		for (spark in sparks) move(spark, seconds);
		var alive = sparks.filter(spark -> spark.life > 0);
		sparks.resize(0);
		for (spark in alive) sparks.push(spark);
		draw();
	}

	/** A burst somewhere in the top two thirds of the screen: sparks flying out in every direction, one colour each. */
	function burst() {
		nextBurst = burstEvery;
		var x = canvas.clientWidth * (0.1 + 0.8 * Math.random());
		var y = canvas.clientHeight * (0.1 + 0.5 * Math.random());
		var colour = colours[Std.random(colours.length)];
		for (_ in 0...sparksInABurst) {
			var angle = 2 * Math.PI * Math.random();
			var speed = burstSpeed * (0.4 + 0.6 * Math.random());
			sparks.push({x: x, y: y, dx: Math.cos(angle) * speed, dy: Math.sin(angle) * speed, colour: colour, life: 1});
		}
	}

	function move(spark:Spark, seconds:Float) {
		spark.x += spark.dx * seconds;
		spark.y += spark.dy * seconds;
		spark.dy += gravity * seconds;
		spark.dx *= 1 - seconds;
		spark.life -= seconds / sparkLives;
	}

	function draw() {
		paint.clearRect(0, 0, canvas.width, canvas.height);
		var scale = canvas.width / Math.max(1, canvas.clientWidth);
		for (spark in sparks) {
			paint.globalAlpha = Math.max(0, spark.life);
			paint.fillStyle = spark.colour;
			paint.fillRect(spark.x * scale - 2 * scale, spark.y * scale - 2 * scale, 4 * scale, 4 * scale);
		}
		paint.globalAlpha = 1;
	}

	/** The canvas as big as the screen, in device pixels. */
	function fitTheScreen() {
		var pixels = Math.min(2, Browser.window.devicePixelRatio);
		var wide = Math.round(canvas.clientWidth * pixels), tall = Math.round(canvas.clientHeight * pixels);
		if (canvas.width != wide || canvas.height != tall) {
			canvas.width = wide;
			canvas.height = tall;
		}
	}
}
