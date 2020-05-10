package why.duplex.peerjs;


@:access(why.duplex.peerjs)
class PeerJsServer implements Server {
	
	public final connected:Signal<Client>;
	public final errors:Signal<Error>;
	
	final peer:Peer;
	
	public function new(peer) {
		this.peer = peer;
		
		connected = new Signal(cb -> {
			peer.on('connection', function onConnect(conn:DataConnection) {
				conn.on('open', () -> cb.invoke((new PeerJsClient(conn):Client)));
			});
			peer.off.bind('connection', onConnect);
		});
		
		errors = new Signal(cb -> {
			peer.on('error', function onError(e) {
				cb.invoke(Error.ofJsError(e));
			});
			peer.off.bind('error', onError);
		});
	}
	
	public static function bind(opt:{key:String, id:String}):Promise<Server> {
		return Future.async(BindContext.new.bind(opt));
	}
}

@:access(why.duplex.peerjs)
private class BindContext {
	final cb:Outcome<Server, Error>->Void;
	final peer:Peer;
	
	public function new(opt, cb) {
		this.cb = cb;
		peer = new Peer(opt.id, opt);
		peer.once('error', onError);
		peer.once('open', onOpen);
	}
	
	function onError(e) {
		peer.off('open', onOpen);
		cb(Failure(Error.ofJsError(e)));
	}
	
	function onOpen(id) {
		peer.off('error', onError);
		cb(Success(new PeerJsServer(peer)));
	}
	
}



