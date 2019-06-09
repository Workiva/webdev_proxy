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

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf_proxy/shelf_proxy.dart' as shelf_proxy;

String _sseHeaders(String origin) => 'HTTP/1.1 200 OK\r\n'
    'Content-Type: text/event-stream\r\n'
    'Cache-Control: no-cache\r\n'
    'Connection: keep-alive\r\n'
    'Access-Control-Allow-Credentials: true\r\n'
    'Access-Control-Allow-Origin: $origin\r\n'
    '\r\n';

/// [SseProxyHandler] proxies two-way communications of JSON encodable data
/// between clients and an [SseHandler].
///
/// This handler provides the same communication interface as [SseHandler], but
/// simply forwards data back and forth between clients and the actual server.
class SseProxyHandler {
  final _httpClient = http.Client();
  shelf.Handler _incomingMessageProxyHandler;
  final _logger = Logger('SseProxyHandler');
  final String _proxyName;
  final Uri _proxyUri;
  final Uri _serverUri;

  /// Creates an SSE proxy handler that will handle EventSource requests to
  /// [proxyUri] by proxying them to [serverUri].
  SseProxyHandler(Uri proxyUri, Uri serverUri, {String proxyName})
      : _proxyUri = proxyUri,
        _serverUri = serverUri,
        _proxyName = proxyName;

  shelf.Handler get handler => _handle;

  Future<shelf.Response> _createSseConnection(
      shelf.Request req, String path) async {
    final serverReq = http.StreamedRequest(
        req.method, _serverUri.replace(query: req.requestedUri.query))
      ..followRedirects = false
      ..headers.addAll(req.headers)
      ..headers['Host'] = _serverUri.authority
      ..sink.close();

    final serverResponse = await _httpClient.send(serverReq);

    req.hijack((channel) {
      final sink = utf8.encoder.startChunkedConversion(channel.sink)
        ..add(_sseHeaders(req.headers['origin']));

      StreamSubscription serverSseSub;
      StreamSubscription reqChannelSub;

      serverSseSub =
          utf8.decoder.bind(serverResponse.stream).listen(sink.add, onDone: () {
        reqChannelSub?.cancel();
        sink.close();
      });

      reqChannelSub = channel.stream.listen((_) {
        // SSE is unidirectional.
      }, onDone: () {
        serverSseSub?.cancel();
        sink.close();
      });
    });
    return shelf.Response.notFound('');
  }

  Future<shelf.Response> _handle(shelf.Request req) async {
    final path = req.requestedUri.path;
    if (path != _proxyUri.path) {
      return shelf.Response.notFound('');
    }

    if (req.headers['accept'] == 'text/event-stream' && req.method == 'GET') {
      return _createSseConnection(req, path);
    }

    if (req.headers['accept'] != 'text/event-stream' && req.method == 'POST') {
      return _handleIncomingMessage(req);
    }

    return shelf.Response.notFound('');
  }

  Future<shelf.Response> _handleIncomingMessage(shelf.Request req) async {
    _incomingMessageProxyHandler ??= shelf_proxy.proxyHandler(
      _serverUri,
      client: _httpClient,
      proxyName: _proxyName,
    );
    return _incomingMessageProxyHandler(req);
  }
}
