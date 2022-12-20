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

@TestOn('vm')
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_static/shelf_static.dart';
import 'package:sse/server/sse_handler.dart';
import 'package:test/test.dart';
import 'package:webdev_proxy/src/port_utils.dart';

import 'package:webdev_proxy/src/webdev_proxy_server.dart';

import 'chromedriver_utils.dart';

void main() {
  WebdevProxyServer proxy;
  HttpServer server;
  SseHandler serverSse;

  setUpAll(() async {
    await startChromeDriver();
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
        await http.get(Uri.parse('http://localhost:${proxy.port}/index.dart'));
    expect(response.statusCode, 200);
    expect(response.body, isNotEmpty);
  });

  test('Proxies the /\$sseHandler endpoint', () async {
    proxy = await WebdevProxyServer.start(
      dir: 'test',
      hostname: 'localhost',
      portToProxy: server.port,
      portToServe: await findUnusedPort(),
    );

    final webDriver = await createWebDriver();
    await webDriver.get('http://localhost:${proxy.port}');
    var connection = await serverSse.connections.next;
    connection.sink.add('blah');
    expect(await connection.stream.first, 'blah');
  });

  test('Rewrites 404s to /index.html when enabled', () async {
    proxy = await WebdevProxyServer.start(
      dir: 'test',
      hostname: 'localhost',
      portToProxy: server.port,
      rewrite404s: true,
    );

    final response = await http
        .get(Uri.parse('http://localhost:${proxy.port}/path/to/nothing'));
    expect(response.statusCode, 200);
    expect(response.body, startsWith('<!DOCTYPE html>'));
  });

  test('Does not rewrite 404s to /index.html when disabled', () async {
    proxy = await WebdevProxyServer.start(
      dir: 'test',
      hostname: 'localhost',
      portToProxy: server.port,
      rewrite404s: false,
    );

    final response = await http
        .get(Uri.parse('http://localhost:${proxy.port}/path/to/nothing'));
    expect(response.statusCode, 404);
  });
}
