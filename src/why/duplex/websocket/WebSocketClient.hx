package why.duplex.websocket;

import js.html.WebSocket;

class WebSocketClient implements Client {
	
	public final disconnected:Future<Option<Error>>;
	public final data:Signal<Chunk>;
	
	final ws:WebSocket;
	
	function new(ws) {
		this.ws = ws;
		ws.binaryType = ARRAYBUFFER;
		
		disconnected = Future.async(function(cb) {
			ws.onerror = function(e) cb(Some(Error.ofJsError(e)));
			ws.onclose = function() cb(None);
		});
		
		data = new Signal(cb -> {
			ws.addEventListener('message', function onMessage(event:{data:Any}) {
				var data = event.data;
				cb.invoke(Std.is(data, String) ? Chunk.ofString(data) : Chunk.ofBytes(Bytes.ofData(data)));
			});
			ws.removeEventListener.bind('message', onMessage);
		});
	}
	
	public function send(data:Chunk):Promise<Noise> {
		ws.send(data.toBytes().getData());
		return Promise.NOISE;
	}
	
	public function disconnect():Future<Noise> {
		ws.close();
		return Future.NOISE;
	}
	
	public static function connect(url:String):Promise<Client> {
		return Future.async(ConenctContext.new.bind(url));
	}
	
	#if nodejs
	static function __init__() {
		untyped global.WebSocket = js.Lib.require('ws');
	}
	#end
}

@:access(why.duplex.websocket)
private class ConenctContext {
	final cb:Outcome<Client, Error>->Void;
	final ws:WebSocket;
	
	public function new(url, cb) {
		this.cb = cb;
		ws = new WebSocket(url);
		ws.addEventListener('error', onError);
		ws.addEventListener('open', onOpen);
	}
	
	function onError(e) {
		ws.removeEventListener('open', onOpen);
		cb(Failure(Error.ofJsError(e)));
	}
	
	function onOpen() {
		ws.removeEventListener('error', onError);
		cb(Success(new WebSocketClient(ws)));
	}
	
}