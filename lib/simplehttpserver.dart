
import 'dart:convert';
import 'dart:io';
import 'dart:async';


typedef Future<String> GetCallback();
typedef Future<String> PostCallback(String body);


/**
 * Simple only for my use
 */
class SimpleHttpServer {

  HttpServer _internalServer;

  File logger;

  Map<String, GetCallback> _getHandlers = new Map<String, GetCallback>();
  Map<String, PostCallback> _postHandlers = new Map<String, PostCallback>();

  void addGetHandler(GetCallback getHandler, String methodHeaderToReactTo){
    _getHandlers[methodHeaderToReactTo] = getHandler;
  }

  void addPostHandler(PostCallback postHandler, String methodHeaderToReactTo){
    _postHandlers[methodHeaderToReactTo] = postHandler;
  }

  Future bindHttpServer(int port) async {
    logger = new File("simplehttpserverRequests.log");
    if (!await logger.exists()) {
      await logger.create();
    }
    _internalServer = await HttpServer.bind("localhost", port);
    print("Server listening on localhost:$port");
    _doRouting();
  }

  Future _doRouting() async {
    _internalServer.listen((HttpRequest request) async {
      String body = await _decodeRequestBody(request);
      _addCorsHeaders(request);
      if (request.method == "OPTIONS"){
        request.response.close();
        return;
      }
      String methodHeader = request.headers["method"]?.first;
      print("responding to request: $methodHeader");
      bool responseWritten = false;
      if (request.method == "GET") {
        GetCallback handler = _getHandlers[methodHeader];
        if (handler != null) {
          request.response.write(await handler());
          responseWritten = true;
        }
      }
      else if (request.method == "POST") {
        PostCallback handler = _postHandlers[methodHeader];
        if (handler != null) {
          request.response.write(await handler(body));
          responseWritten = true;
        }
      }
      if (!responseWritten) {
        request.response.statusCode = 400;
        request.response.reasonPhrase = "This method does not exist";
      }
      request.response.close();
      if (!responseWritten) {
        logger.writeAsStringSync(
            logger.readAsStringSync() + "\n" +
            new DateTime.now().toIso8601String() + " " +
            request.method + " " +
            request.uri.toString() + " " +
            request.headers.toString().split("\n").join(" ")
        );
      }
    });
  }

  static Future<String> _decodeRequestBody(HttpRequest request) async {
    return request.transform(UTF8.decoder).join();
  }

  static void _addCorsHeaders(HttpRequest request){
    request.response.headers.set("Allow", "OPTIONS,GET,POST");
    request.response.headers.set("Access-Control-Allow-Origin", "*");
    request.response.headers.set("Access-Control-Allow-Headers", "method");
  }

}
