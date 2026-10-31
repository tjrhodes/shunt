package hud;

import input.Controller;

/** Every word the player sees, in one place. */
class Words {
	public static inline final gameName = "shunt";
	public static inline final tagline = "Short-track stock cars. Bumping is allowed.";
	public static inline final start = "Start the race";
	public static inline final raceAgain = "Race again";
	public static inline final changeTrack = "Change track";
	public static inline final soundIsOn = "Sound: on";
	public static inline final soundIsOff = "Sound: off";
	public static inline final track = "Track";
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
	public static inline final drivers = "Drivers";
	public static inline final aiDriver = "AI";
	public static inline final anyControls = "Keys, pad or touch";
	public static inline final joinHint = "More players: press go on your own keys (W or ↑) or gamepad (right trigger) to take a seat; brake to give it back.";

	// ---- Online ----
	public static inline final online = "Online";
	public static inline final raceOnline = "Race online";
	public static inline final quickMatch = "Quick match";
	public static inline final raceFriends = "Race friends";
	public static inline final joinFriends = "Join the race";
	public static inline final invited = "You've been invited to a race.";
	public static inline final raceAlone = "Race on your own instead";
	public static inline final onlineHelp = "Quick match puts you in with anyone looking for a race. Race friends gives you a link to send them. Everyone on this computer comes too.";
	public static inline final connecting = "Getting you a seat…";
	public static inline final cantConnect = "Couldn't reach the race. It may have finished, or the server is down. Try again in a moment.";
	public static inline final roomLink = "Send this link to the people you want to race:";
	public static inline final copy = "Copy";
	public static inline final copied = "Copied";
	public static inline final leave = "Leave";
	public static inline final youAreTheHost = "You're the host: pick a track and start when everyone's in.";
	public static inline final waitingForTheHost = "Waiting for the host to start.";
	public static inline final waitingToStart = "Waiting for one more person to start.";
	public static inline final watching = "Every seat is taken: you're watching this race, and get a seat in the next.";

	/** A quick match's start, counting down. */
	public static function startsIn(seconds:Float):String {
		return 'Starting in ${Math.ceil(seconds)} s';
	}

	/** The made-up sponsors on the billboards round the track. */
	public static final billboards = ["SHUNT", "LAP COLA", "DENTCO", "GRIPSTER TYRES", "OIL? NO", "BUMPER & SONS"];

	/** How to drive, one line per way of driving. */
	public static final howToDrive = [
		"Keyboard: arrows or WASD; hold a steering key longer to turn harder. R (or / for the arrows) puts you back on the track. Esc pauses. M turns the sound off or on.",
		"Gamepad: right trigger to go, left trigger to brake, stick to steer, Y to be put back. Start pauses; Select turns the sound off or on.",
		"Touch: hold the left or right side to steer. You accelerate on your own; the pad brakes."
	];

	/** "1st", "2nd", "3rd", "4th". */
	public static function place(position:Int):String {
		var endings = ["th", "st", "nd", "rd"];
		var lastTwo = position % 100;
		var ending = lastTwo >= 11 && lastTwo <= 13 ? "th" : endings[position % 10] ?? "th";
		return '$position$ending';
	}

	/** A seat's name: "You" for the one person here racing alone, "Player 2" for anyone else, or the AI car's number. */
	public static function driverName(seat:Int, number:Int, isAPerson:Bool, isYouAlone:Bool):String {
		if (!isAPerson) return 'No. $number';
		return isYouAlone ? you : 'Player ${seat + 1}';
	}

	/** A person's short tag in the HUD: "P2". */
	public static function playerTag(seat:Int):String {
		return 'P${seat + 1}';
	}

	/** What a controller is called on the seat picker. */
	public static function controllerName(controller:Controller):String {
		return switch controller {
			case KeyboardLeft: "WASD";
			case KeyboardRight: "Arrows";
			case Pad(slot): 'Gamepad ${slot + 1}';
			case Touch: "Touch";
		}
	}

	/** Seconds as a race clock shows them, to the tenth: "1:04.3", or "19.6" under a minute. */
	public static function raceTime(seconds:Float):String {
		var tenths = Math.round(seconds * 10);
		var minutes = Std.int(tenths / 600);
		var wholeSeconds = Std.int((tenths % 600) / 10);
		var secondsText = minutes > 0 && wholeSeconds < 10 ? '0$wholeSeconds' : '$wholeSeconds';
		return (minutes > 0 ? '$minutes:' : "") + '$secondsText.${tenths % 10}';
	}

	/** A track as the picker offers it: "Serpentine · 3 laps". */
	public static function trackChoice(name:String, laps:Int):String {
		return '$name · $laps laps';
	}

	/** A count out of a total, as the HUD shows laps and places: "3 / 5". */
	public static function outOf(count:Int, total:Int):String {
		return '$count / $total';
	}
}
