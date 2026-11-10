package shunt.tournament;

/** A tournament as the online room tells the browsers about it: plain data, to send. */
typedef TournamentView = {
	final tracks:Array<Int>;
	final racesRun:Int;
	final points:Array<Int>;
	final wins:Array<Int>;
}

/**
 * A tournament (Tom, 4 Nov): a run of 3, 5 or 10 races on different tracks,
 * with points for each finish, 3 for a win, 2 for second, 1 for third,
 * none for fourth, and a winner when they're all run.
 *
 * The tracks start as a random pick (no track twice, while there are enough
 * of them), and any can be swapped for another before the first race. The AI
 * drivers stay the same people all the way through: each race's seed comes
 * from the tournament's, keeping the same kind of driver in each seat (see
 * `seedForARace`).
 *
 * Online (Tom, 5 Nov), a room can run one: the server keeps it, and tells
 * the browsers how it stands with `view` (they rebuild it with `fromView`).
 */
class Tournament {
	/** How many races a tournament can be. */
	public static final lengths = [3, 5, 10];

	/** Points for finishing first, second, third and fourth. */
	public static final pointsForPlaces = [3, 2, 1, 0];

	/** The tracks to race, in order (each an index into the game's tracks). */
	public final tracks:Array<Int> = [];

	/** Each seat's points so far, and how many races it has won (which settles a tie on points). */
	public final points:Array<Int>;
	public final wins:Array<Int>;

	/** How many races have been run (and scored). */
	public var racesRun(default, null) = 0;

	/** Picks a whole number below the one given: the game's is random, the checks' isn't. */
	final pick:Int -> Int;
	final trackCount:Int;
	final seed:Int;

	public function new(trackCount:Int, length:Int, seats:Int, pick:Int -> Int) {
		this.trackCount = trackCount;
		this.pick = pick;
		seed = pick(1000000) + 1;
		points = [for (_ in 0...seats) 0];
		wins = [for (_ in 0...seats) 0];
		resize(length);
	}

	/** The tracks a room was asked to race, if they make a tournament: a usual length, every one a real track. */
	public static function isATournament(tracks:Dynamic, trackCount:Int):Bool {
		if (!Std.isOfType(tracks, Array) || !lengths.contains(tracks.length)) return false;
		return Lambda.foreach((tracks : Array<Dynamic>), track -> Std.isOfType(track, Int) && track >= 0 && track < trackCount);
	}

	/** A tournament on these tracks, in this order. */
	public static function on(tracks:Array<Int>, trackCount:Int, seats:Int, pick:Int -> Int):Tournament {
		var tournament = new Tournament(trackCount, tracks.length, seats, pick);
		for (race in 0...tracks.length) tournament.swap(race, tracks[race]);
		return tournament;
	}

	/** A tournament as a room told it (for showing its standings: it can't pick seeds). */
	public static function fromView(view:TournamentView):Tournament {
		var tournament = on(view.tracks, view.tracks.length, view.points.length, _ -> 0);
		for (seat in 0...view.points.length) {
			tournament.points[seat] = view.points[seat];
			tournament.wins[seat] = view.wins[seat];
		}
		tournament.racesRun = view.racesRun;
		return tournament;
	}

	/** How it stands, as plain data to send. */
	public function view():TournamentView {
		return {tracks: tracks.copy(), racesRun: racesRun, points: points.copy(), wins: wins.copy()};
	}

	/** The same tracks again, from no points (a room's next tournament). */
	public function again() {
		for (seat in 0...points.length) points[seat] = wins[seat] = 0;
		racesRun = 0;
	}

	// ---- Before the first race: choosing the tracks ----

	/** Makes the tournament this many races long: tracks already chosen stay, new ones are picked at random. */
	public function resize(length:Int) {
		tracks.resize(Std.int(Math.min(tracks.length, length)));
		while (tracks.length < length) tracks.push(anotherTrack());
	}

	/** A fresh random pick of tracks, as many as before. */
	public function shuffle() {
		var length = tracks.length;
		tracks.resize(0);
		resize(length);
	}

	/** One race's track changed for another. */
	public function swap(race:Int, track:Int) {
		tracks[race] = track;
	}

	/** A track at random, one not in the tournament yet if there's one left. */
	function anotherTrack():Int {
		var unused = [for (track in 0...trackCount) if (!tracks.contains(track)) track];
		return unused.length > 0 ? unused[pick(unused.length)] : pick(trackCount);
	}

	// ---- Racing it ----

	/** The track of the race to run next (or the last, once it's over). */
	public function nextTrack():Int {
		return tracks[Std.int(Math.min(racesRun, tracks.length - 1))];
	}

	/** Whether every race has been run. */
	public function isOver():Bool {
		return racesRun >= tracks.length;
	}

	/**
	 * A seed for one of the tournament's races: different every race, but the
	 * same remainder by 3 as the tournament's, which is what decides the kind of
	 * AI driver in each seat (`DriverCharacters.kindOf`). So the Ace stays the
	 * Ace from the first race to the last.
	 */
	public function seedForARace():Int {
		return seed + 3 * (pick(100000) + 1);
	}

	/** A race finished: points and wins for the seats in their finishing order. */
	public function score(finishingOrder:Array<Int>) {
		for (place in 0...finishingOrder.length) points[finishingOrder[place]] += pointsForPlaces[Std.int(Math.min(place, pointsForPlaces.length - 1))];
		wins[finishingOrder[0]]++;
		racesRun++;
	}

	/** The seats from first to last on points; a tie goes to more wins, then to the lower seat. */
	public function standings():Array<Int> {
		var seats = [for (seat in 0...points.length) seat];
		seats.sort((a, b) -> points[a] != points[b] ? points[b] - points[a] : (wins[a] != wins[b] ? wins[b] - wins[a] : a - b));
		return seats;
	}
}
