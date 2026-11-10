import { readFileSync } from "node:fs";
import { join } from "node:path";
import { settings } from "./Settings.js";

/** The text of every track file, in the order `tracks/index.json` lists them: the same files the game and the checks read. */
export function trackTexts(): string[] {
	const read = (name: string) => readFileSync(join(settings.tracksFolder, name), "utf8");
	const names: string[] = JSON.parse(read("index.json"));
	return names.map(read);
}
