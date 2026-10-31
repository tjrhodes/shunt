package online;

import js.lib.Promise;

/*
 * Haxe descriptions of the few parts of the Colyseus browser client
 * (`colyseus.js`, served by the shunt server as the global `Colyseus`)
 * the game uses: finding or making a room, and talking in it.
 */

@:native("Colyseus.Client") extern class ColyseusClient {
	function new(server:String);
	function create(roomType:String, ?options:Dynamic):Promise<ColyseusRoom>;
	function joinOrCreate(roomType:String, ?options:Dynamic):Promise<ColyseusRoom>;
	function joinById(roomId:String, ?options:Dynamic):Promise<ColyseusRoom>;
}

extern class ColyseusRoom {
	var roomId(default, null):String;

	/** This browser's name in the room. */
	var sessionId(default, null):String;

	function send(type:String, ?message:Dynamic):Void;
	function onMessage(type:String, heard:Dynamic -> Void):() -> Void;
	function leave(?consented:Bool):Promise<Int>;

	/** Called with what to do once the room is left, however that happens. */
	function onLeave(then:Int -> Void):Void;
}
