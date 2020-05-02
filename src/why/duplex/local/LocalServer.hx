package why.duplex.local;

import haxe.Timer;

@:access(why.duplex.local)
class LocalServer implements Server {
	public final connected:Signal<Client>;
	public final errors:Signal<Error>;
	
	final _connected:SignalTrigger<Client>;
	
	public function new() {
		connected = _connected = Signal.trigger();
		errors = Signal.trigger();
	}
	
	function add(client:LocalClient) {
		var remote = new ConnectedLocalClient(client);
		Timer.delay(_connected.trigger.bind(remote), 0);
		return remote;
	}
}

@:access(why.duplex.local)
class ConnectedLocalClient implements Client {
	
	public final disconnected:Future<Option<Error>>;
	public final data:Signal<Chunk>;
	
	final _data:SignalTrigger<Chunk>;
	
	final remote:LocalClient;
	
	public function new(client:LocalClient) {
		this.remote = client;
		disconnected = remote.disconnected;
		data = _data = Signal.trigger();
	}
	
	public function send(data:Chunk):Promise<Noise> {
		return remote.receive(data);
	}
	
	public function disconnect():Future<Noise> {
		return remote.disconnect();
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