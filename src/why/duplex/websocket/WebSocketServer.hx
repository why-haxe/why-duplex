package why.duplex.websocket;

import js.html.WebSocket;
import js.lib.Set;
import haxe.Timer;
import haxe.Constraints.Function;

@:access(why.duplex.websocket)
class WebSocketServer implements Server {
	public final connected:Signal<Client>;
	public final errors:Signal<Error>;

	final server:NativeServer;

	public function new(server:NativeServer) {
		this.server = server;

		connected = new Signal(cb -> {
			server.on('connection', function onConnect(socket:WebSocket) {
				untyped socket.unresponsive = 0;
				untyped socket.on('pong', heartbeat);

				cb((new WebSocketClient(socket) : Client));
			});
			server.off.bind('connection', onConnect);
		});

		errors = new Signal(cb -> {
			server.on('error', function onError(e) {
				cb(Error.ofJsError(e));
			});
			server.off.bind('error', onError);
		});

		// setup heartbeat
		// https://github.com/websockets/ws#how-to-detect-and-close-broken-connections
		var timer = new Timer(10000);
		timer.run = function() {
			for (socket in server.clients) {
				if (untyped socket.unresponsive > 3) {
					untyped socket.terminate();
				}
				untyped socket.unresponsive++;
				untyped socket.ping(noop);
			}
		}

		server.on('close', timer.stop);
	}

	public function close():Future<Noise> {
		return Future.async(function(cb) {
			server.close(cb.bind(Noise));
		});
	}

	public static function bind(opt):Promise<Server> {
		return Future.async(BindContext.new.bind(opt));
	}

	static function noop() {}

	static function heartbeat() {
		js.Lib.nativeThis.unresponsive--;
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
	var clients:Set<WebSocket>;
	function new(opt:{});
	function on(event:String, f:Function):Void;
	function once(event:String, f:Function):Void;
	function off(event:String, f:Function):Void;
	function close(f:Function):Void;
}
