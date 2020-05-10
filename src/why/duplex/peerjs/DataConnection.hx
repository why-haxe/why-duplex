package why.duplex.peerjs;

import js.lib.ArrayBuffer;
import haxe.Constraints;

extern class DataConnection {
	function on(event:String, f:Function):Dynamic;
	function off(event:String, f:Function):Dynamic;
	function send(data:ArrayBuffer):Void;
	function close():Void;
}