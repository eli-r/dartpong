library dartpong;

import 'dart:async';
import 'dart:io';

import 'package:http_server/http_server.dart' as http_server;
import 'package:route/server.dart' show Router;

const int PORT = 8080;

void handleWebSocket(WebSocket socket){
  print('websocket connection');
}

void main(){
  var webPath = Platform.script.resolve('../web').toFilePath();
  if(!new Directory(webPath).existsSync()){
    print('error! web directory not found');
  }

  HttpServer.bind(InternetAddress.LOOPBACK_IP_V4, PORT).then((server){
    print('server running on ${server.address.address}:$PORT');
    var router = new Router(server);

    //upgrade websocket requests to /ws
    router.serve('/ws')
          .transform(new WebSocketTransformer())
          .listen(handleWebSocket);
    
    //set up default handler to serve web files
    var virDir = new http_server.VirtualDirectory(webPath);
    virDir.jailRoot = false;
    virDir.allowDirectoryListing = true;
    virDir.directoryHandler = (dir, req){
      //redirect directory requests to index.html files
      var indexUri = new Uri.file(dir.path).resolve('index.html');
      virDir.serveFile(new File(indexUri.toFilePath()), req);
    };

    //add an error page handler
    virDir.errorPageHandler = (HttpRequest req){
      print('resource not found: ${req.uri.path}');
      req.response.statusCode = HttpStatus.NOT_FOUND;
      req.response.close();
    };

    //serve everything else not routed through the virtual directory
    virDir.serve(router.defaultStream);
  });
}
