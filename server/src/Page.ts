import { createReadStream, existsSync, statSync } from "node:fs";
import { extname, join, normalize } from "node:path";
import type { IncomingMessage, ServerResponse } from "node:http";
import { settings } from "./Settings.js";

/** What each kind of file is served as. */
const kinds: Record<string, string> = {
	".html": "text/html; charset=utf-8",
	".js": "text/javascript; charset=utf-8",
	".json": "application/json",
	".css": "text/css",
};

/** Tells the page it has an online server to talk to (the claude.ai copy has none, so it stays offline). */
const onlineNote = JSON.stringify({ online: true });

/**
 * Serves the game's page and its files from the built client, plus the
 * Colyseus browser script and a note saying online racing is here. Only
 * files inside the page's folder can be reached; anything else is passed on
 * (Colyseus answers its own requests, for finding and joining rooms).
 */
export function servePage(request: IncomingMessage, response: ServerResponse, passOn: () => void) {
	const path = new URL(request.url ?? "/", "http://here").pathname;
	if (path === "/online.json") return send(response, 200, kinds[".json"], onlineNote);
	if (path === "/colyseus.js") return sendFile(response, settings.colyseusScript);
	const file = normalize(join(settings.pageFolder, path === "/" ? "index.html" : path));
	const isInside = file.startsWith(normalize(settings.pageFolder));
	if (!isInside || !existsSync(file) || !statSync(file).isFile()) return passOn();
	sendFile(response, file);
}

function sendFile(response: ServerResponse, file: string) {
	response.writeHead(200, { "Content-Type": kinds[extname(file)] ?? "application/octet-stream", "Cache-Control": file.endsWith(".html") ? "no-cache" : "public, max-age=3600" });
	createReadStream(file).pipe(response);
}

function send(response: ServerResponse, status: number, kind: string, body: string) {
	response.writeHead(status, { "Content-Type": kind });
	response.end(body);
}
