import { createServer } from "node:http";
import { Server, WebSocketTransport } from "colyseus";
import { ShuntRoom } from "./ShuntRoom.js";
import { servePage } from "./Page.js";
import { settings } from "./Settings.js";

/**
 * The shunt server (SPEC.md §9): one process that serves the game's page
 * and runs the online rooms. Quick matches are grouped together; every
 * other room is reached only by its link.
 */
const server = new Server({
	transport: new WebSocketTransport({ server: createServer() }),
	express: (app) => app.use(servePage),
	greet: false,
});
server.define("race", ShuntRoom).filterBy(["quick"]);
await server.listen(settings.port, settings.host);
console.log(`shunt is on http://${settings.host}:${settings.port}`);
