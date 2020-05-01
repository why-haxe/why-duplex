package;

import why.duplex.websocket.WebSocketClient;
import why.duplex.websocket.WebSocketServer;

using tink.CoreApi;

@:asserts
class WebSocketTest {
	public function new() {}
	
	public function test() {
		WebSocketServer.bind({port: 8080})
			.next(server -> {
				var serverLog = new StringBuf();
				var clientLog = new StringBuf();
				server.connected.handle(client -> {
					serverLog.add('connected,');
					client.data.handle(chunk -> serverLog.add(chunk.toString() + ','));
					client.send('welcome');
				});
				WebSocketClient.connect('ws://localhost:8080')
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