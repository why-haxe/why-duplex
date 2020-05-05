package why.duplex.websocket;

import haxe.Constraints.Function;

@:access(why.duplex.websocket)
class WebSocketServer implements Server {
	public final connected:Signal<Client>;
	public final errors:Signal<Error>;
	final server:NativeServer;

	public function new(server:NativeServer) {
		this.server = server;
		
		connected = new Signal(cb -> {
			server.on('connection', function onConnect(socket) {
				cb.invoke((new WebSocketClient(socket):Client));
			});
			server.off.bind('connection', onConnect);
		});
		
		errors = new Signal(cb -> {
			server.on('error', function onError(e) {
				cb.invoke(Error.ofJsError(e));
			});
			server.off.bind('error', onError);
		});
	}

	public function close():Future<Noise> {
		return Future.async(function(cb) {
			server.close(cb.bind(Noise));
		});
	}
	
	public static function bind(opt):Promise<Server> {
		return Future.async(BindContext.new.bind(opt));
	}
}

@:access(why.duplex.websocket)
private class BindContext {
	final cb:Outcome<Server, Error>->Void;
	final server:NativeServer;
	
	public function new(opt, cb) {
		this.cb = cb;
		server = new NativeServer(opt);
		server.once('error', onError);
		server.once('listening', onListening);
	}
	
	function onError(e) {
		server.off('listening', onListening);
		cb(Failure(Error.ofJsError(e)));
	}
	
	function onListening() {
		server.off('error', onError);
		cb(Success(new WebSocketServer(server)));
	}
	
}

@:jsRequire('ws', 'Server')
private extern class NativeServer {
	function new(opt:{});
	function on(event:String, f:Function):Void;
	function once(event:String, f:Function):Void;
	function off(event:String, f:Function):Void;
	function close(f:Function):Void;
}