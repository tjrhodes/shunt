import { join } from "node:path";

/** The server's own folder: it is always started from there (`npm start`, and the system service). */
const serverFolder = process.cwd();

/**
 * Everything about where the server runs, in one place. Each can be set
 * from outside (the deploy script does) and falls back to the repo's own
 * layout, so it also runs straight from a checkout.
 */
export const settings = {
	port: Number(process.env.SHUNT_PORT ?? 2567),
	host: process.env.SHUNT_HOST ?? "127.0.0.1",
	pageFolder: process.env.SHUNT_PAGE ?? join(serverFolder, "../client/www"),
	tracksFolder: process.env.SHUNT_TRACKS ?? join(serverFolder, "../tracks"),
	colyseusScript: join(serverFolder, "node_modules/@colyseus/sdk/dist/colyseus.js"),
};
