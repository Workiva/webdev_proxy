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

class SseProxyHandler {
  final _httpClient = http.Client();
  shelf.Handler _incomingMessageProxyHandler;
  final _logger = Logger('SseProxyHandler');
  final String _proxyName;
  final Uri _proxyUri;
  final Uri _serverUri;

  SseProxyHandler(this._proxyUri, this._serverUri, {String proxyName})
      : _proxyName = proxyName;

  shelf.Handler get handler => _handle;

  Future<shelf.Response> _createSseConnection(
      shelf.Request req, String path) async {
    final serverReq = http.StreamedRequest(
        req.method, _serverUri.replace(query: req.requestedUri.query));
    serverReq
      ..followRedirects = false
      ..headers.addAll(req.headers)
      ..headers['Host'] = _serverUri.authority
      ..sink.close();

    final serverResponse = await _httpClient.send(serverReq);
    _logger.fine('... proxy-->server SSE connection established.');

    req.hijack((channel) {
      final sink = utf8.encoder.startChunkedConversion(channel.sink)
        ..add(_sseHeaders(req.headers['origin']));
      _logger.fine('... client-->proxy SSE connection established.');

      StreamSubscription serverSseSub;
      StreamSubscription reqChannelSub;

      serverSseSub = utf8.decoder.bind(serverResponse.stream).listen((data) {
        // Forward data from server to client.
        sink.add(data);
      }, onDone: () {
        _logger.fine('... proxy-->server SSE connection closed by server.');
        reqChannelSub?.cancel();
        sink.close();
      });

      reqChannelSub = channel.stream.listen((_) {
        // SSE is unidirectional.
      }, onDone: () {
        _logger.fine('... client-->proxy SSE connection closed by client.');
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
