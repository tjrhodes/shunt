// What the TypeScript sees of the Haxe-built room (lib/race-room.cjs, from
// sim/src/shunt/online). Only the parts the server calls are described.

export declare const Messages: {
	takeSeats: string;
	chooseTrack: string;
	startRace: string;
	inputs: string;
	room: string;
	raceStarts: string;
	snapshot: string;
};

export declare const OnlineTuning: {
	mostBrowsers: number;
};

export declare class RaceRoom {
	/** Made as a browser asked: a quick match or not, the first track, a tournament's tracks by number (the room checks them all). */
	constructor(trackTexts: string[], asked: { quick?: boolean; track?: unknown; tournament?: unknown }, outbox: { toEveryone: (type: string, message: unknown) => void });
	arrive(session: string): void;
	wantSeats(session: string, wanted: unknown): void;
	depart(session: string): void;
	chooseTrack(session: string, choice: unknown): void;
	startRace(session: string): void;
	takeInputs(session: string, batch: unknown): void;
	advance(nowMilliseconds: number): void;
}
