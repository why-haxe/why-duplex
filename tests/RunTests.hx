package ;

import tink.unit.*;
import tink.testrunner.*;
import why.duplex.*;
import why.duplex.local.*;
import why.duplex.websocket.*;

using tink.CoreApi;

class RunTests {

  static function main() {
    Runner.run(TestBatch.make([
      new DuplexTest(WebSocketServer.bind.bind({port: 8080}), WebSocketClient.connect.bind('ws://localhost:8080')),
      {
        var server = new LocalServer();
        new DuplexTest(Promise.resolve.bind((server:Server)), LocalClient.connect.bind(server));
      },
    ])).handle(Runner.exit);
  }
  
}