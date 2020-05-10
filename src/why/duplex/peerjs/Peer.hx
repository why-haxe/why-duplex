package why.duplex.peerjs;

import haxe.Constraints;

@:native('Peer')
extern class Peer {
	function new(?id:String, ?opt:{});
	function on(event:String, f:Function):Dynamic;
	function off(event:String, f:Function):Dynamic;
	function once(event:String, f:Function):Void;
	function connect(id:String):DataConnection;
} 

