package online;

/** Ways into an online race. */
enum HowToJoin {
	/** Any open quick match, or a new one. */
	QuickMatch;

	/** A new room of your own, reached only by its link. */
	NewRoom;

	/** Friends' room, from its link. */
	RoomById(id:String);
}
