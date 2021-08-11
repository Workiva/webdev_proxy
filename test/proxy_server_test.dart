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

import 'dart:convert';
@TestOn('vm')
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_static/shelf_static.dart';
import 'package:sse/server/sse_handler.dart';
import 'package:test/test.dart';
import 'package:webdriver/io.dart';

import 'package:webdev_proxy/src/webdev_proxy_server.dart';

void main() {
  Process chromeDriver;
  WebdevProxyServer proxy;
  HttpServer server;
  SseHandler serverSse;

  setUpAll(() async {
    try {
      chromeDriver = await Process.start(
          'chromedriver', ['--port=4444', '--url-base=wd/hub']);

      // On windows this takes a while to boot up, wait for the first line
      // of stdout as a signal that it is ready.
      final stdOutLines = chromeDriver.stdout
          .transform(utf8.decoder)
          .transform(LineSplitter())
          .asBroadcastStream();

      final stdErrLines = chromeDriver.stderr
          .transform(utf8.decoder)
          .transform(LineSplitter())
          .asBroadcastStream();

      stdOutLines.listen((line) => print('ChromeDriver stdout: $line'));
      stdErrLines.listen((line) => print('ChromeDriver stderr: $line'));

      await stdOutLines.first;
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
    server = await shelf_io.serve(
        serverCascade.handler, 'localhost', await findUnusedPort());
  });

  tearDown(() async {
    await proxy.close();
    await server.close(force: true);
  });

  test('Proxies URL that exists', () async {
    proxy = await WebdevProxyServer.start(
      dir: 'test',
      hostname: 'localhost',
      portToProxy: server.port,
      portToServe: await findUnusedPort(),
    );

    final response =
        await http.get('http://127.0.0.1:${proxy.port}/index.dart');
    expect(response.statusCode, 200);
    expect(response.body, isNotEmpty);
  });

  test('Proxies the /\$sseHandler endpoint', () async {
    proxy = await WebdevProxyServer.start(
      dir: 'test',
      hostname: '127.0.0.1',
      portToProxy: server.port,
      portToServe: await findUnusedPort(),
    );

    print(':::PORTS:::');
    print('proxy: ${proxy.port}');
    print('server: ${server.port}');
    print('chromedriver: http://127.0.0.1:4444/wd/hub');

    final capabilities = Capabilities.chrome
      ..addAll({
        Capabilities.chromeOptions: {
          'args': ['--headless'],
        }
      });
    final webdriver = await createDriver(
        spec: WebDriverSpec.JsonWire,
        desired: capabilities,
        uri: Uri.parse('http://127.0.0.1:4444/wd/hub'));
    addTearDown(webdriver.quit);

    await webdriver.get('http://127.0.0.1:${proxy.port}');
    var connection = await serverSse.connections.next;
    connection.sink.add('blah');
    expect(await connection.stream.first, 'blah');
  });

  test('Rewrites 404s to /index.html when enabled', () async {
    proxy = await WebdevProxyServer.start(
      dir: 'test',
      hostname: '127.0.0.1',
      portToProxy: server.port,
      rewrite404s: true,
    );

    final response =
        await http.get('http://127.0.0.1:${proxy.port}/path/to/nothing');
    expect(response.statusCode, 200);
    expect(response.body, startsWith('<!DOCTYPE html>'));
  });

  test('Does not rewrite 404s to /index.html when disabled', () async {
    proxy = await WebdevProxyServer.start(
      dir: 'test',
      hostname: '127.0.0.1',
      portToProxy: server.port,
      rewrite404s: false,
    );

    final response =
        await http.get('http://127.0.0.1:${proxy.port}/path/to/nothing');
    expect(response.statusCode, 404);
  });
}

/// Returns a port that is probably, but not definitely, not in use.
///
/// This has a built-in race condition: another process may bind this port at
/// any time after this call has returned.
Future<int> findUnusedPort() async {
  int port;
  ServerSocket socket;
  try {
    socket =
        await ServerSocket.bind(InternetAddress.loopbackIPv6, 0, v6Only: true);
  } on SocketException {
    socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  }
  port = socket.port;
  await socket.close();
  return port;
}
