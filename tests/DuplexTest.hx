package;

import why.duplex.*;

using tink.CoreApi;

@:asserts
class DuplexTest {
	final createServer:()->Promise<Server>;
	final createClient:()->Promise<Client>;
	
	public function new(createServer, createClient) {
		this.createServer = createServer;
		this.createClient = createClient;
	}
	
	public function test() {
		createServer()
			.next(server -> {
				var serverLog = new StringBuf();
				var clientLog = new StringBuf();
				server.connected.handle(client -> {
					serverLog.add('connected,');
					client.data.handle(chunk -> serverLog.add(chunk.toString() + ','));
					client.send('welcome');
				});
				createClient()
					.next(client -> {
						client.data.handle(chunk -> clientLog.add(chunk.toString() + ','));
						client.send('hello');
					})
					.next(_ -> Future.delay(100, Noise))
					.next(_ -> {
						asserts.assert(serverLog.toString() == 'connected,hello,');
						asserts.assert(clientLog.toString() == 'welcome,');
					});
			})
			.handle(asserts.handle);
			
		return asserts;
	}
}