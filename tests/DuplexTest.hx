package;

import why.duplex.*;
import tink.Chunk;

using tink.CoreApi;
using DuplexTest.ClientTools;
using DuplexTest.ServerTools;

@:asserts
class DuplexTest {
	final createServer:()->Promise<Server>;
	final createClient:()->Promise<Client>;
	
	public function new(createServer, createClient) {
		this.createServer = createServer;
		this.createClient = createClient;
	}
	
	@:describe("Connect, send some data, then disconnect from client side")
	public function test1() {
		createServer()
			.next(server -> {
				Promise.inParallel([
					server.waitForConnection()
						.next(client -> {
							client.waitForData()
								.next(data -> {
									asserts.assert(data.toString() == 'hello');
									client.send('welcome');
								})
								.next(_ -> client.disconnected)
								.next(err -> asserts.assert(err == None));
						})
						.noise(),
					createClient()
						.next(client -> {
							client.send('hello')
								.next(_ -> client.waitForData())
								.next(data -> {
									asserts.assert(data.toString() == 'welcome');
									client.disconnect();
								})
								.next(_ -> client.disconnected)
								.next(err -> asserts.assert(err == None));
						})
						.noise(),
				])
				.next(_ -> server.close());
			})
			.handle(asserts.handle);
			
		return asserts;
	}

	@:describe("Connect, send some data, then disconnect from server side")
	public function test2() {
		createServer()
			.next(server -> {
				Promise.inParallel([
					server.waitForConnection()
						.next(client -> {
							client.waitForData()
								.next(data -> {
									asserts.assert(data.toString() == 'hello');
									client.send('welcome');
								})
								.next(_ -> client.disconnect())
								.next(_ -> client.disconnected)
								.next(err -> asserts.assert(err == None));
						})
						.noise(),
					createClient()
						.next(client -> {
							client.send('hello')
								.next(_ -> client.waitForData())
								.next(data -> asserts.assert(data.toString() == 'welcome'))
								.next(_ -> client.disconnected)
								.next(err -> asserts.assert(err == None));
						})
						.noise(),
				])
				.next(_ -> server.close());
			})
			.handle(asserts.handle);
			
		return asserts;
	}

	@:describe("Connect, send some data, then close server")
	public function test3() {
		createServer()
			.next(server -> {
				Promise.inParallel([
					server.waitForConnection()
						.next(client -> {
							client.waitForData()
								.next(data -> {
									asserts.assert(data.toString() == 'hello');
									client.send('welcome');
								})
								.next(_ -> server.close());
						})
						.noise(),
					createClient()
						.next(client -> {
							client.send('hello')
								.next(_ -> client.waitForData())
								.next(data -> asserts.assert(data.toString() == 'welcome'))
								.next(_ -> client.disconnected)
								.next(err -> asserts.assert(err == None));
						})
						.noise(),
				]);
			})
			.handle(asserts.handle);
			
		return asserts;
	}
}

class ServerTools {
	static final TIMED_OUT = new Error('Timed out');
	public static function waitForConnection(server:Server, timeout = 1000):Promise<Client> {
		return server.connected.nextTime().map(Success).first(Future.delay(timeout, Failure(TIMED_OUT)));
	}
}

class ClientTools {
	static final TIMED_OUT = new Error('Timed out');
	public static function waitForData(client:Client, timeout = 1000):Promise<Chunk> {
		return client.data.nextTime().map(Success).first(Future.delay(timeout, Failure(TIMED_OUT)));
	}
}