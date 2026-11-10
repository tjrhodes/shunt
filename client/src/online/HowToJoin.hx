package online;

/** Ways into an online race. */
enum HowToJoin {
	/** Any open quick match, or a new one. */
	QuickMatch;

	/** A new room of your own, reached only by its link. */
	NewRoom;

	/** A new room of your own for a tournament on these tracks (by number, in order), reached only by its link. */
	NewTournament(tracks:Array<Int>);

	/** Friends' room, from its link. */
	RoomById(id:String);
}
