import 'dart:io';

import 'package:http_multi_server/http_multi_server.dart';
import 'package:io/ansi.dart';
import 'package:meta/meta.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_proxy/shelf_proxy.dart' as shelf_proxy;
import 'package:webdev_proxy/src/proxy_root_index_handler.dart';
import 'package:webdev_proxy/src/sse_proxy_handler.dart';

import 'logging.dart';

class ProxyServer {
  final HttpServer _server;

  ProxyServer._(this._server);

  int get port => _server.port;

  static Future<ProxyServer> start({
    @required String dir,
    @required String hostname,
    @required int portToProxy,
    int portToServe,
    bool rewrite404s,
  }) async {
    portToServe ??= 0;
    rewrite404s ??= true;

    final serverHostname = hostname == 'any' ? 'localhost' : hostname;
    final serverUri = Uri.parse('http://$serverHostname:$portToProxy');
    final serverSseUri = serverUri.replace(path: r'/$sseHandler');
    final sseUri = Uri.parse(r'/$sseHandler');

    final proxyHandler =
        shelf_proxy.proxyHandler(serverUri, proxyName: 'webdev_proxy');
    var cascade = shelf.Cascade()
        .add(SseProxyHandler(sseUri, serverSseUri).handler)
        .add(proxyHandler);
    if (rewrite404s) {
      cascade = cascade.add(proxyRootIndexHandler(proxyHandler));
    }

    final server = await HttpMultiServer.bind(hostname, portToServe);
    shelf_io.serveRequests(server, cascade.handler);
    final proxyHostname = hostname == 'any' ? '::' : hostname;
    log.info(green.wrap('Serving `$dir` proxy on '
            'http://$proxyHostname:$portToServe') +
        '\n');
    log.fine('... forwards to http://$serverHostname:$portToProxy');
    return ProxyServer._(server);
  }

  Future<Null> close() async {
    await _server.close(force: true);
  }
}
