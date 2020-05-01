package why.duplex;

interface Client {
	final disconnected:Future<Option<Error>>;
	final data:Signal<Chunk>;
	function send(data:Chunk):Promise<Noise>;
	function disconnect():Future<Noise>;
}