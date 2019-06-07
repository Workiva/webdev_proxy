import 'package:shelf/shelf.dart' as shelf;

shelf.Handler proxyRootIndexHandler(shelf.Handler proxyHandler) {
  return (shelf.Request req) {
    final indexRequest = shelf.Request(
        'GET', req.requestedUri.replace(path: '/'),
        context: req.context,
        encoding: req.encoding,
        headers: req.headers,
        protocolVersion: req.protocolVersion);
    return proxyHandler(indexRequest);
  };
}
