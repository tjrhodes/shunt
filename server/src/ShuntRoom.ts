import { Room, Client } from "colyseus";
import { performance } from "node:perf_hooks";
import { createRequire } from "node:module";
import type { RaceRoom as RaceRoomType } from "../lib/race-room.cjs";

/** The room's brain, built from the Haxe (an old-style CommonJS file, so it is required rather than imported). */
const { RaceRoom, Messages, OnlineTuning } = createRequire(import.meta.url)("../lib/race-room.cjs") as typeof import("../lib/race-room.cjs");
import { trackTexts } from "./Tracks.js";

/** How often the race is looked at, in milliseconds: it then runs however many 1/120 s ticks are due. */
const lookEvery = 1000 / 120;

/**
 * One online room (SPEC.md §9), as Colyseus sees it. It only passes
 * messages between the browsers and the room's brain, `RaceRoom`, written
 * in Haxe with the rest of the game: every decision is made there.
 */
export class ShuntRoom extends Room {
	maxClients = OnlineTuning.mostBrowsers;
	brain!: RaceRoomType;

	/** A quick match can be joined by anyone looking for a race; any other room only by its link, and it may be for a tournament (its tracks, by number). */
	onCreate(options: { quick?: boolean; tournament?: number[] }) {
		const quick = options?.quick === true;
		if (!quick) this.setPrivate(true);
		const outbox = { toEveryone: (type: string, message: unknown) => this.broadcast(type, message) };
		this.brain = new RaceRoom(trackTexts(), quick, outbox, options?.tournament);
		this.passMessagesToTheBrain();
		this.setSimulationInterval(() => this.brain.advance(performance.now()), lookEvery);
	}

	/** Every message a browser can send goes straight to the brain, with who sent it. */
	passMessagesToTheBrain() {
		this.onMessage(Messages.takeSeats, (client, wanted) => this.brain.wantSeats(client.sessionId, wanted));
		this.onMessage(Messages.chooseTrack, (client, choice) => this.brain.chooseTrack(client.sessionId, choice));
		this.onMessage(Messages.startRace, (client) => this.brain.startRace(client.sessionId));
		this.onMessage(Messages.inputs, (client, batch) => this.brain.takeInputs(client.sessionId, batch));
	}

	onJoin(client: Client) {
		this.brain.arrive(client.sessionId);
	}

	onLeave(client: Client) {
		this.brain.depart(client.sessionId);
	}
}
