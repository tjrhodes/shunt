package hud;

/** Every word the player sees, in one place. */
class Words {
	public static inline final gameName = "shunt";
	public static inline final tagline = "Short-track stock cars. Bumping is allowed.";
	public static inline final start = "Start the race";
	public static inline final raceAgain = "Race again";
	public static inline final resume = "Resume";
	public static inline final restart = "Restart";
	public static inline final paused = "Paused";
	public static inline final pause = "Pause";
	public static inline final brake = "Brake";
	public static inline final position = "Position";
	public static inline final lap = "Lap";
	public static inline final thisLap = "This lap";
	public static inline final bestLap = "Best";
	public static inline final results = "Results";
	public static inline final you = "You";
	public static inline final noTimeYet = "–";

	/** How to drive, one line per way of driving. */
	public static final howToDrive = [
		"Keyboard: arrows or WASD; hold a steering key longer to turn harder. R puts you back on the track. Esc pauses.",
		"Gamepad: right trigger to go, left trigger to brake, stick to steer.",
		"Touch: hold the left or right side to steer. You accelerate on your own; the pad brakes."
	];

	/** "1st", "2nd", "3rd", "4th". */
	public static function place(position:Int):String {
		var endings = ["th", "st", "nd", "rd"];
		var lastTwo = position % 100;
		var ending = lastTwo >= 11 && lastTwo <= 13 ? "th" : endings[position % 10] ?? "th";
		return '$position$ending';
	}

	/** A seat's name in the results: "You", or the car's number. */
	public static function driverName(seat:Int, number:Int):String {
		return seat == 0 ? you : 'No. $number';
	}

	/** Seconds as a race clock shows them, to the tenth: "1:04.3", or "19.6" under a minute. */
	public static function raceTime(seconds:Float):String {
		var tenths = Math.round(seconds * 10);
		var minutes = Std.int(tenths / 600);
		var wholeSeconds = Std.int((tenths % 600) / 10);
		var secondsText = minutes > 0 && wholeSeconds < 10 ? '0$wholeSeconds' : '$wholeSeconds';
		return (minutes > 0 ? '$minutes:' : "") + '$secondsText.${tenths % 10}';
	}

	/** A count out of a total, as the HUD shows laps and places: "3 / 5". */
	public static function outOf(count:Int, total:Int):String {
		return '$count / $total';
	}
}
