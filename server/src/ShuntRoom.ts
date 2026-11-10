import { Room, Client, CloseCode } from "colyseus";
import { performance } from "node:perf_hooks";
import { createRequire } from "node:module";
import type { RaceRoom as RaceRoomType } from "../lib/race-room.cjs";

/** The room's brain, built from the Haxe (an old-style CommonJS file, so it is required rather than imported). */
const { RaceRoom, Messages, OnlineTuning } = createRequire(import.meta.url)("../lib/race-room.cjs") as typeof import("../lib/race-room.cjs");
import { trackTexts } from "./Tracks.js";

/** How often the race is looked at, in milliseconds: it then runs however many 1/120 s ticks are due. */
const lookEvery = 1000 / 120;

/** How long someone whose connection dropped has to come back before their seat goes (the browser reconnects by itself). */
const secondsToComeBack = 20;

/**
 * One online room (SPEC.md §9), as Colyseus sees it. It only passes
 * messages between the browsers and the room's brain, `RaceRoom`, written
 * in Haxe with the rest of the game: every decision is made there.
 */
export class ShuntRoom extends Room {
	maxClients = OnlineTuning.mostBrowsers;
	brain!: RaceRoomType;

	/** A quick match can be joined by anyone looking for a race; any other room only by its link. The brain checks the rest of what was asked (the first track, a tournament). */
	onCreate(options: { quick?: boolean; track?: number; tournament?: number[] }) {
		if (options?.quick !== true) this.setPrivate(true);
		const outbox = {
			toEveryone: (type: string, message: unknown) => this.broadcast(type, message),
			log: (line: string) => this.log(line),
		};
		this.brain = new RaceRoom(trackTexts(), options ?? {}, outbox);
		this.passMessagesToTheBrain();
		this.setSimulationInterval(() => this.brain.advance(performance.now()), lookEvery);
	}

	/** Every message a browser can send goes straight to the brain, with who sent it. */
	passMessagesToTheBrain() {
		this.onMessage(Messages.takeSeats, (client, wanted) => this.brain.wantSeats(client.sessionId, wanted));
		this.onMessage(Messages.chooseTrack, (client, choice) => this.brain.chooseTrack(client.sessionId, choice));
		this.onMessage(Messages.startRace, (client) => this.brain.startRace(client.sessionId));
		this.onMessage(Messages.inputs, (client, batch) => this.brain.takeInputs(client.sessionId, batch));
		this.onMessage(Messages.ping, (client, sent) => client.send(Messages.pong, sent));
	}

	onJoin(client: Client) {
		this.brain.arrive(client.sessionId);
	}

	/**
	 * Someone has gone. If they meant to, their seat goes at once. If their
	 * connection dropped (Tom, 10 Nov: a friend racing from the north of Italy
	 * was dropped twice and landed on the track cards), their browser tries to
	 * reconnect by itself, and they have a while to; their car carries on
	 * meanwhile. Either way the server's log says who went and why.
	 */
	async onLeave(client: Client, code?: number) {
		this.log(`${client.sessionId} left (close code ${code})`);
		if (code === CloseCode.CONSENTED) return this.brain.depart(client.sessionId);
		try {
			await this.allowReconnection(client, secondsToComeBack);
			this.log(`${client.sessionId} came back`);
		} catch {
			this.log(`${client.sessionId} didn't come back in ${secondsToComeBack} s`);
			this.brain.depart(client.sessionId);
		}
	}

	/** A line in the server's log, marked with the room. */
	log(line: string) {
		console.log(`[room ${this.roomId}] ${line}`);
	}
}
