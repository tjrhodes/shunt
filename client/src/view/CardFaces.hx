package view;

import hud.Words;
import js.html.CanvasElement;
import js.html.CanvasRenderingContext2D;
import shunt.track.Track;

/**
 * Painting the track cards for the ring: the face (the track's map, its
 * name, family, and laps and length) and the back (the game's name on a
 * pattern), in the game's colours and type.
 */
class CardFaces {
	/** A card's face, painted on a canvas. */
	public static function front(track:Track, canvas:CanvasElement):CanvasElement {
		var paint = canvas.getContext2d();
		var wide = canvas.width;
		cardGround(paint, canvas, Paint.cardFace);
		drawTheMap(paint, track, wide * 0.1, wide * 0.1, wide * 0.8);
		words(paint, track.name, Lettering.heavy(Math.round(wide * 0.15)), Paint.cardWords, wide * 0.1, canvas.height * 0.8);
		words(paint, (Words.families.get(track.family) ?? "").toUpperCase(), '600 ${Math.round(wide * 0.05)}px "Fira Sans", sans-serif', Paint.cardQuietWords, wide * 0.1, canvas.height * 0.87);
		words(paint, Words.lapsAndLength(track.laps, track.length), '500 ${Math.round(wide * 0.06)}px "Fira Sans", sans-serif', Paint.cardQuietWords, wide * 0.1, canvas.height * 0.94);
		return canvas;
	}

	/** A card's back: the game's name across it, on stripes in the palette. */
	public static function back(canvas:CanvasElement):CanvasElement {
		var paint = canvas.getContext2d();
		cardGround(paint, canvas, Paint.cardBack);
		stripes(paint, canvas);
		paint.textAlign = "center";
		words(paint, Words.gameName, Lettering.heavy(Math.round(canvas.width * 0.24)), Paint.cardWords, canvas.width / 2, canvas.height * 0.55);
		return canvas;
	}

	/** Diagonal stripes right across the card. */
	static function stripes(paint:CanvasRenderingContext2D, canvas:CanvasElement) {
		paint.strokeStyle = Paint.css(Paint.cardStripes);
		paint.lineWidth = canvas.width * 0.05;
		for (step in -4...12) {
			var x = step * canvas.width * 0.18;
			paint.beginPath();
			paint.moveTo(x, 0);
			paint.lineTo(x + canvas.height * 0.6, canvas.height);
			paint.stroke();
		}
	}

	/** The card itself: filled, with a thin edge. */
	static function cardGround(paint:CanvasRenderingContext2D, canvas:CanvasElement, colour:Int) {
		paint.fillStyle = Paint.css(colour);
		paint.fillRect(0, 0, canvas.width, canvas.height);
		paint.strokeStyle = Paint.css(Paint.cardEdge);
		paint.lineWidth = canvas.width * 0.02;
		paint.strokeRect(0, 0, canvas.width, canvas.height);
	}

	/** The track's walls (from `TrackMap`), in a square at a place on the card. */
	static function drawTheMap(paint:CanvasRenderingContext2D, track:Track, left:Float, top:Float, across:Float) {
		paint.save();
		paint.translate(left, top);
		paint.scale(across / TrackMap.size, across / TrackMap.size);
		paint.strokeStyle = Paint.css(Paint.cardMap);
		paint.lineWidth = 1.8;
		paint.lineCap = "round";
		paint.stroke(new js.html.Path2D(TrackMap.pathOf(track)));
		paint.restore();
	}

	static function words(paint:CanvasRenderingContext2D, text:String, font:String, colour:Int, x:Float, y:Float) {
		paint.font = font;
		paint.fillStyle = Paint.css(colour);
		paint.fillText(text, x, y);
	}
}
