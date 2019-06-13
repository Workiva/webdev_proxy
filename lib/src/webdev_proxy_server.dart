// Copyright 2019 Workiva Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

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

/// A wrapper around an [HttpServer] configured to proxy the server spawned by a
/// `webdev serve` process.
class WebdevProxyServer {
  final HttpServer _server;

  WebdevProxyServer._(this._server);

  /// Returns the port that this server is listening on.
  int get port => _server.port;

  /// Permanently stops this proxy server from listening for new connections and
  /// closes all active connections immediately.
  Future<Null> close() async {
    await _server.close(force: true);
  }

  /// Starts a proxy for a webdev server that is serving [dir] and listening on
  /// [hostname] and [portToProxy].
  ///
  /// The proxy will listen on [portToServe], which defaults to `0` meaning that
  /// the server will pick any available port.
  ///
  /// The proxy will rewrite any request to the webdev server that 404s to a
  /// request that fetches the root index path (`/`) unless [rewrite404s] is
  /// false.
  static Future<WebdevProxyServer> start({
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
    return WebdevProxyServer._(server);
  }
}
