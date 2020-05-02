package why.duplex.local;

import haxe.Timer;

@:access(why.duplex.local)
class LocalClient implements Client {
	
	public final disconnected:Future<Option<Error>>;
	public final data:Signal<Chunk>;
	
	final _disconnected:FutureTrigger<Option<Error>>;
	final _data:SignalTrigger<Chunk>;
	
	final remote:LocalServer.ConnectedLocalClient;
	
	public function new(server:LocalServer) {
		remote = server.add(this);
		disconnected = _disconnected = Future.trigger();
		data = _data = Signal.trigger();
	}
	
	public static function connect(server:LocalServer):Promise<Client> {
		var client = new LocalClient(server);
		return Future.delay(0, Success((client:Client)));
	}
	
	public function send(data:Chunk):Promise<Noise> {
		return remote.receive(data);
	}
	
	public function disconnect():Future<Noise> {
		_data.clear();
		_disconnected.trigger(None);
		return Future.NOISE;
	}
	
	function receive(data:Chunk) {
		return Future.async(function(cb) {
			Timer.delay(function() {
				_data.trigger(data);
				cb(Noise);
			}, 0);
		});
	}
}