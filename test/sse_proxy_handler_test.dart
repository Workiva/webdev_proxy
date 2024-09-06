@TestOn('vm')
import 'dart:async';
import 'dart:io';

import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_static/shelf_static.dart';
import 'package:sse/server/sse_handler.dart';
import 'package:test/test.dart';
import 'package:webdev_proxy/src/port_utils.dart';
import 'package:webdriver/async_io.dart';

import 'package:webdev_proxy/src/sse_proxy_handler.dart';

import 'chromedriver_utils.dart';

void main() {
  late HttpServer proxy;
  late HttpServer server;
  late SseHandler serverSse;
  late WebDriver webdriver;

  setUpAll(() async {
    await startChromeDriver();
  });

  setUp(() async {
    const ssePath = r'/$sseHandler';

    final staticWebHandler = createStaticHandler('test/web',
        listDirectories: true, defaultDocument: 'index.html');

    serverSse = SseHandler(Uri.parse(ssePath));
    final serverCascade = shelf.Cascade().add(serverSse.handler);
    server = await io.serve(
        serverCascade.handler, 'localhost', await findUnusedPort());

    final proxySse = SseProxyHandler(Uri.parse(ssePath),
        Uri.parse('http://localhost:${server.port}$ssePath'));
    final proxyCascade = shelf.Cascade()
        .add(proxySse.handler)
        .add(_faviconHandler)
        .add(staticWebHandler);
    proxy = await io.serve(
        proxyCascade.handler, 'localhost', await findUnusedPort());

    webdriver = await createWebDriver();
  });

  tearDown(() async {
    await proxy.close();
    await server.close();
  });

  test('Can round trip messages', () async {
    await webdriver.get('http://localhost:${proxy.port}');

    // Give webdriver more time to get its act together?
    await Future.delayed(Duration(seconds: 3));

    var connection = await serverSse.connections.next;
    connection.sink.add('blah');
    expect(await connection.stream.first, 'blah');
  });

  test('Multiple clients can connect', () async {
    var connections = serverSse.connections;
    await webdriver.get('http://localhost:${proxy.port}');
    var conn1 = await connections.next;
    conn1.sink.add('one');
    expect(await conn1.stream.first, 'one');
    await webdriver.get('http://localhost:${proxy.port}');
    var conn2 = await connections.next;
    conn2.sink.add('two');
    expect(await conn2.stream.first, 'two');
  });

  test('Routes data correctly', () async {
    var connections = serverSse.connections;
    await webdriver.get('http://localhost:${proxy.port}');
    var connectionA = await connections.next;
    connectionA.sink.add('foo');
    expect(await connectionA.stream.first, 'foo');

    await webdriver.get('http://localhost:${proxy.port}');
    var connectionB = await connections.next;
    connectionB.sink.add('bar');
    expect(await connectionB.stream.first, 'bar');
  });

  test('Can close from the server', () async {
    expect(serverSse.numberOfClients, 0);
    await webdriver.get('http://localhost:${proxy.port}');
    var connection = await serverSse.connections.next;
    expect(serverSse.numberOfClients, 1);
    await connection.sink.close();
    await pumpEventQueue();
    expect(serverSse.numberOfClients, 0);
  });

  test('Can close from the client-side', () async {
    expect(serverSse.numberOfClients, 0);
    await webdriver.get('http://localhost:${proxy.port}');
    var connection = await serverSse.connections.next;
    expect(serverSse.numberOfClients, 1);

    var closeButton = await webdriver.findElement(const By.tagName('button'));
    await closeButton.click();

    // Should complete since the connection is closed.
    await connection.stream.toList();
    expect(serverSse.numberOfClients, 0);
  });

  test('Cancelling the listener closes the connection', () async {
    expect(serverSse.numberOfClients, 0);
    await webdriver.get('http://localhost:${proxy.port}');
    var connection = await serverSse.connections.next;
    expect(serverSse.numberOfClients, 1);

    var sub = connection.stream.listen((_) {});
    await sub.cancel();
    await pumpEventQueue();
    expect(serverSse.numberOfClients, 0);
  });

  test('Disconnects when navigating away', () async {
    await webdriver.get('http://localhost:${proxy.port}');
    await serverSse.connections.next;
    expect(serverSse.numberOfClients, 1);

    await webdriver.get('chrome://version/');
    await Future.delayed(Duration(seconds: 1));

    expect(serverSse.numberOfClients, 0);
  });
}

FutureOr<shelf.Response> _faviconHandler(shelf.Request request) {
  if (request.url.path.endsWith('favicon.ico')) {
    return shelf.Response.ok('');
  }
  return shelf.Response.notFound('');
}
