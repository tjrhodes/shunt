package online;

import js.Browser;
import js.html.Element;

/** Whose car a correction moved: one of ours, another person's, or an AI driver's. */
enum CarKind {
	Ours;
	SomeoneElses;
	AnAi;
}

/**
 * The `?net` readout (Tom, 5 Nov: a race with his son lagged, cars jumped,
 * and nothing said why). Add `?net` to the address and a line at the
 * bottom of the screen says, every half second, how an online race is
 * keeping up:
 *
 * - ping: how long a message takes to the server and back;
 * - ahead: how many ticks this browser runs ahead of the server's last
 *   snapshot (its inputs the server hasn't used yet);
 * - snapshots a second, frames a second and the slowest frame;
 * - the largest correction lately, for our cars, other people's and the AI's.
 */
class NetReadout {
	static inline final everySeconds = 0.5;
	static inline final pingEverySeconds = 1.0;

	final box:Element;
	var ping = -1.0;
	var lastPingAt = -1e9;
	var seconds = 0.0;
	var lastFrameAt = -1.0;
	var frames = 0;
	var slowestFrame = 0.0;
	var snapshots = 0;
	var ahead = 0;
	final largest = [Ours => 0.0, SomeoneElses => 0.0, AnAi => 0.0];

	/** Whether the page's address asks for it. */
	public static function isWanted():Bool {
		return new js.html.URLSearchParams(Browser.location.search).has("net");
	}

	public function new() {
		box = Browser.document.createDivElement();
		box.className = "net-readout";
		Browser.document.body.appendChild(box);
	}

	/** Whether it's time to measure the ping again (the time to send, in milliseconds). */
	public function wantsAPing(nowMilliseconds:Float):Bool {
		if (nowMilliseconds - lastPingAt < pingEverySeconds * 1000) return false;
		lastPingAt = nowMilliseconds;
		return true;
	}

	/** A ping came back, sent at this time (milliseconds, the page's clock). */
	public function heardPong(sentAt:Float) {
		ping = Browser.window.performance.now() - sentAt;
	}

	/** A snapshot moved a car this far. */
	public function corrected(kind:CarKind, metres:Float) {
		largest[kind] = Math.max(largest[kind], metres);
	}

	public function heardASnapshot() {
		snapshots++;
	}

	/** A frame went by (at this time, in milliseconds: its real length is measured, however slow); now and then the line is written afresh. */
	public function frame(nowMilliseconds:Float, ticksAhead:Int) {
		var secondsSinceLastFrame = lastFrameAt < 0 ? 0 : (nowMilliseconds - lastFrameAt) / 1000;
		lastFrameAt = nowMilliseconds;
		frames++;
		seconds += secondsSinceLastFrame;
		slowestFrame = Math.max(slowestFrame, secondsSinceLastFrame);
		ahead = ticksAhead;
		if (seconds < everySeconds) return;
		box.textContent = line();
		forgetTheLastHalfSecond();
	}

	function line():String {
		var each = (count:Int) -> Math.round(count / seconds);
		var metres = (kind:CarKind) -> '${Math.round(largest[kind] * 100) / 100} m';
		var pingWords = ping < 0 ? "…" : '${Math.round(ping)} ms';
		var timing = 'ping $pingWords · ahead $ahead ticks · ${each(snapshots)} snapshots/s · ${each(frames)} fps, slowest ${Math.round(slowestFrame * 1000)} ms';
		return '$timing · largest jumps: ours ${metres(Ours)}, others\' ${metres(SomeoneElses)}, AI ${metres(AnAi)}';
	}

	function forgetTheLastHalfSecond() {
		seconds = 0;
		frames = snapshots = 0;
		slowestFrame = 0;
		for (kind in largest.keys()) largest[kind] = 0;
	}
}
