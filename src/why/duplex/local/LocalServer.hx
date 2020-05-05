package why.duplex.local;

@:access(why.duplex.local)
class LocalServer implements Server {
	public final connected:Signal<Client>;
	public final errors:Signal<Error>;

	final clients:Array<Client>;
	
	final _connected:SignalTrigger<Client>;
	
	public function new() {
		clients = [];
		connected = _connected = Signal.trigger();
		errors = Signal.trigger();
	}

	public function close() {
		while(clients.length > 0) clients.pop().disconnect();
		_connected.clear();
		return Future.NOISE;
	}
	
	function add(client:LocalClient) {
		var remote = new ConnectedLocalClient(client);
		clients.push(remote);
		remote.disconnected.handle(function(_) clients.remove(client));
		Callback.defer(_connected.trigger.bind(remote));
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
		return Future.delay(0, Noise)
			.map(function(v) {
				_data.trigger(data);
				return v;
			});
	}
}