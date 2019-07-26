import 'package:shelf/shelf.dart';

Iterable<Handler> get handlers => [
      customStatusHandler,
    ];

Iterable<Middleware> get middleware => [
      rewriteMiddleware,
    ];

Response customStatusHandler(Request request) {
  final customStatus = request.requestedUri.queryParameters['status'];
  if (customStatus != null) {
    return Response(int.parse(customStatus));
  }
  return Response.notFound('');
}

Handler rewriteMiddleware(Handler innerHandler) {
  return (originalReq) {
    var req = originalReq;
    if (req.requestedUri.queryParameters['rewrite'] != null) {
      req = _copyRequest(req, req.requestedUri.replace(path: '/rewrite.html'));
    }
    return innerHandler(req);
  };
}

Request _copyRequest(Request oldRequest, [Uri newPath]) {
  newPath ??= oldRequest.url;
  return Request(oldRequest.method, newPath,
      protocolVersion: oldRequest.protocolVersion,
      headers: oldRequest.headers,
      body: oldRequest.read(),
      encoding: oldRequest.encoding,
      context: oldRequest.context);
}
