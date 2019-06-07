@TestOn('vm')
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_static/shelf_static.dart';
import 'package:sse/server/sse_handler.dart';
import 'package:test/test.dart';
import 'package:webdev_proxy/src/proxy_server.dart';
import 'package:webdriver/io.dart';

void main() {
  Process chromeDriver;
  ProxyServer proxy;
  HttpServer server;
  SseHandler serverSse;

  setUpAll(() async {
    try {
      chromeDriver = await Process.start(
          'chromedriver', ['--port=4444', '--url-base=wd/hub']);
    } catch (e) {
      throw StateError(
          'Could not start ChromeDriver. Is it installed?\nError: $e');
    }
  });

  tearDownAll(() {
    chromeDriver.kill();
  });

  setUp(() async {
    final staticWebHandler = createStaticHandler('test/web',
        listDirectories: true, defaultDocument: 'index.html');

    serverSse = SseHandler(Uri.parse(r'/$sseHandler'));
    final serverCascade =
        shelf.Cascade().add(serverSse.handler).add(staticWebHandler);
    server = await shelf_io.serve(serverCascade.handler, 'localhost', 0);
  });

  tearDown(() async {
    await proxy.close();
    await server.close(force: true);
  });

  test('Proxies URL that exists', () async {
    proxy = await ProxyServer.start(
      dir: 'test',
      hostname: 'localhost',
      portToProxy: server.port,
    );

    final response =
        await http.get('http://localhost:${proxy.port}/index.dart');
    expect(response.statusCode, 200);
    expect(response.body, isNotEmpty);
  });

  test('Proxies the /\$sseHandler endpoint', () async {
    proxy = await ProxyServer.start(
      dir: 'test',
      hostname: 'localhost',
      portToProxy: server.port,
    );

    final webdriver = await createDriver(desired: {
      'chromeOptions': {
        'args': ['--headless']
      }
    });
    addTearDown(() async {
      await webdriver.quit();
    });

    await webdriver.get('http://localhost:${proxy.port}');
    var connection = await serverSse.connections.next;
    connection.sink.add('blah');
    expect(await connection.stream.first, 'blah');
  });

  test('Rewrites 404s to /index.html when enabled', () async {
    proxy = await ProxyServer.start(
      dir: 'test',
      hostname: 'localhost',
      portToProxy: server.port,
      rewrite404s: true,
    );

    final response =
        await http.get('http://localhost:${proxy.port}/path/to/nothing');
    expect(response.statusCode, 200);
    expect(response.body, startsWith('<!DOCTYPE html>'));
  });

  test('Does not rewrite 404s to /index.html when disabled', () async {
    proxy = await ProxyServer.start(
      dir: 'test',
      hostname: 'localhost',
      portToProxy: server.port,
      rewrite404s: false,
    );

    final response =
        await http.get('http://localhost:${proxy.port}/path/to/nothing');
    expect(response.statusCode, 404);
  });
}
