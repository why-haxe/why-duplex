package why.duplex.peerjs;

import js.lib.ArrayBuffer;

class PeerJsClient implements Client {
	
	public final disconnected:Future<Option<Error>>;
	public final data:Signal<Chunk>;
	
	final conn:DataConnection;
	
	function new(conn) {
		this.conn = conn;
		
		disconnected = Future.async(function(cb) {
			conn.on('error', function(e) {
				trace(e);
				cb(Some(Error.ofJsError(e)));
			});
			conn.on('close', function() cb(None));
		});
		
		data = new Signal(cb -> {
			conn.on('data', function onData(data:ArrayBuffer) {
				cb.invoke(Chunk.ofBytes(Bytes.ofData(data)));
			});
			
			conn.off.bind('data', onData);
		}).until(disconnected);
	}
	
	public function send(data:Chunk):Promise<Noise> {
		trace('send ${data.toString()}');
		conn.send(data.toBytes().getData());
		return Promise.NOISE;
	}
	
	public function disconnect():Future<Noise> {
		conn.close();
		return Future.NOISE;
	}
	
	public static function connect(opt:{key:String, id:String}):Promise<Client> {
		return Future.async(ConenctContext.new.bind(opt));
	}
}

@:access(why.duplex.peerjs)
private class ConenctContext {
	final cb:Outcome<Client, Error>->Void;
	final conn:DataConnection;
	
	public function new(opt, cb) {
		this.cb = cb;
		conn = new Peer({key: opt.key}).connect(opt.id);
		conn.on('error', onError);
		conn.on('open', onOpen);
	}
	
	function onError(e) {
		conn.off('open', onOpen);
		cb(Failure(Error.ofJsError(e)));
	}
	
	function onOpen() {
		conn.off('error', onError);
		cb(Success(new PeerJsClient(conn)));
	}
	
}
