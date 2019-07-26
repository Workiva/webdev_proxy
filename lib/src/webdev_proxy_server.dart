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
import 'package:shelf/shelf.dart';
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
    Iterable<Handler> customHandlers,
    Iterable<Middleware> customMiddleware,
    int portToServe,
    bool rewrite404s,
  }) async {
    customHandlers ??= [];
    customMiddleware ??= [];
    portToServe ??= 0;
    rewrite404s ??= true;

    // Construct our handler using a Cascade and starting with custom handlers
    // if any were provided.
    var cascade = shelf.Cascade();
    for (final customHandler in customHandlers ?? []) {
      cascade = cascade.add(customHandler);
    }

    // Add the proxy handler for the `/$sseHandler` route to the cascade.
    final serverHostname = hostname == 'any' ? 'localhost' : hostname;
    final serverUri = Uri.parse('http://$serverHostname:$portToProxy');
    final serverSseUri = serverUri.replace(path: r'/$sseHandler');
    final sseUri = Uri.parse(r'/$sseHandler');
    cascade = cascade.add(SseProxyHandler(sseUri, serverSseUri).handler);

    // Add the default handler for all requests that proxies the webdev server.
    final proxyHandler =
        shelf_proxy.proxyHandler(serverUri, proxyName: 'webdev_proxy');
    cascade = cascade.add(proxyHandler);

    // Add the 404-to-root-index rewrite handler, if enabled.
    if (rewrite404s) {
      cascade = cascade.add(proxyRootIndexHandler(proxyHandler));
    }

    // Construct our final handler by creating a pipeline with custom middleware
    // (if any were provided) and our cascade handler.
    var pipeline = Pipeline();
    for (final middleware in customMiddleware) {
      pipeline = pipeline.addMiddleware(middleware);
    }
    final handler = pipeline.addHandler(cascade.handler);

    final server = await HttpMultiServer.bind(hostname, portToServe);
    shelf_io.serveRequests(server, handler);
    final proxyHostname = hostname == 'any' ? '::' : hostname;
    log.info(green.wrap('Serving `$dir` proxy on '
            'http://$proxyHostname:$portToServe') +
        '\n');
    log.fine('... forwards to http://$serverHostname:$portToProxy');
    return WebdevProxyServer._(server);
  }
}
