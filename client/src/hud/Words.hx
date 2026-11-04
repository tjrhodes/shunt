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
	public static inline final freeSeat = "Free seat";

	/** The three kinds of AI driver, in `DriverCharacters`' order, and what each is like. */
	public static final aiKinds = ["Ace", "Bruiser", "Steady"];
	public static final aiKindsAre = ["Quick and clean", "Shoves you aside", "Keeps out of trouble"];

	// ---- Choosing a track, then the drivers ----
	public static inline final chooseATrack = "Choose a track";
	public static inline final thisTrack = "Race here";
	public static inline final previousTrack = "Previous track";
	public static inline final nextTrack = "Next track";
	public static inline final back = "Back";
	public static inline final useThisTrack = "Use this track";

	// ---- Trophies ----
	public static inline final trophy = "Trophy";
	public static inline final trophyRules = "A run of races, with points for each: 3 for a win, 2 for second, 1 for third. Most points takes the trophy.";
	public static inline final shuffle = "Shuffle";
	public static inline final swap = "Swap";
	public static inline final chooseDrivers = "Choose drivers";
	public static inline final standings = "Standings";
	public static inline final newTrophy = "New trophy";
	public static inline final leaveTheTrophy = "Leave the trophy";

	public static function races(count:Int):String {
		return '$count races';
	}

	/** Under the standings: how far through the trophy. */
	public static function racesRun(run:Int, of:Int):String {
		return run >= of ? 'All $of races run' : 'After $run of $of races';
	}

	/** The drivers panel's line in a trophy: which race, where. */
	public static function trophyRace(race:Int, of:Int, name:String, laps:Int):String {
		return 'Trophy race $race of $of: ' + racingOn(name, laps);
	}

	public static function nextRace(trackName:String):String {
		return 'Next: $trackName';
	}

	public static function trophyWinner(name:String):String {
		return name == you ? "You win the trophy!" : '$name wins the trophy';
	}

	public static function points(count:Int):String {
		return count == 1 ? "1 pt" : '$count pts';
	}

	public static function wins(count:Int):String {
		return count == 1 ? "1 win" : '$count wins';
	}

	/** The drivers panel says which track the race is on: "Serpentine, 3 laps". */
	public static function racingOn(name:String, laps:Int):String {
		return '$name, $laps laps';
	}

	/** What each family of track is called on its card (by the family's name in the track file). */
	public static final families = ["oval" => "Oval", "arena" => "Arena maze", "circuit" => "Circuit", "crossing" => "Crossing"];

	/** A track's laps and length, on its card: "3 laps · 650 m". */
	public static function lapsAndLength(laps:Int, metres:Float):String {
		return '$laps laps · ${Math.round(metres / 10) * 10} m';
	}
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
	public static inline final youAreTheHost = "You're the host: change the track if you like, and start when everyone's in.";
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

	/** A seat's name: "You" for the one person here racing alone, "Player 2" for anyone else, or an AI driver's name (its kind). */
	public static function driverName(seat:Int, aiName:String, isAPerson:Bool, isYouAlone:Bool):String {
		if (!isAPerson) return aiName;
		return isYouAlone ? you : 'Player ${seat + 1}';
	}

	/** The results' headline: who won. */
	public static function winner(name:String):String {
		return name == you ? "You win!" : '$name wins';
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

	/** A count out of a total, as the HUD shows laps and places: "3 / 5". */
	public static function outOf(count:Int, total:Int):String {
		return '$count / $total';
	}
}
