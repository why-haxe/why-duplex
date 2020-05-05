package why.duplex.local;

@:access(why.duplex.local)
class LocalClient implements Client {
	
	public final disconnected:Future<Option<Error>>;
	public final data:Signal<Chunk>;
	
	final _disconnected:FutureTrigger<Option<Error>>;
	final _data:SignalTrigger<Chunk>;
	
	final remote:LocalServer.ConnectedLocalClient;
	
	public function new(server:LocalServer) {
		disconnected = _disconnected = Future.trigger();
		data = _data = Signal.trigger();
		remote = server.add(this);
	}
	
	public static function connect(server:LocalServer):Promise<Client> {
		var client = new LocalClient(server);
		return Future.delay(0, Success((client:Client)));
	}
	
	public function send(data:Chunk):Promise<Noise> {
		return remote.receive(data);
	}
	
	public function disconnect():Future<Noise> {
		return Future.delay(0, Noise)
			.map(function(v) {
				_data.clear();
				_disconnected.trigger(None);
				return v;
			});
	}
	
	function receive(data:Chunk) {
		return Future.delay(0, Noise)
			.map(function(v) {
				_data.trigger(data);
				return v;
			});
	}
}