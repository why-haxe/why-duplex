package ;

import tink.unit.*;
import tink.testrunner.*;
import why.duplex.*;
import why.duplex.local.*;
import why.duplex.websocket.*;
import why.duplex.peerjs.*;

using tink.CoreApi;

class RunTests {

  static function main() {
    Runner.run(TestBatch.make([
      #if js
        #if nodejs
        new DuplexTest(WebSocketServer.bind.bind({port: 8080}), WebSocketClient.connect.bind('ws://localhost:8080')),
        #else
        {
          var opt = {id: 'why-duplex-${Std.random(1<<28)}', key: 'lwjd5qra8257b9'}
          new DuplexTest(PeerJsServer.bind.bind(opt), PeerJsClient.connect.bind(opt));
        },
        #end
      #end
      {
        var server:LocalServer = null;
        new DuplexTest(() -> Promise.resolve((server = new LocalServer():Server)), () -> LocalClient.connect(server));
      },
    ])).handle(Runner.exit);
  }
  
}