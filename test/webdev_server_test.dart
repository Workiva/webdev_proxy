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
import 'package:http/http.dart' as http;
import 'package:test/test.dart';
import 'package:webdev_proxy/src/port_utils.dart';
import 'package:webdev_proxy/src/webdev_server.dart';

void main() async {
  WebdevServer webdevServer;

  tearDown(() async {
    await webdevServer?.close();
  });

  test('Serves a directory', () async {
    final port = await findAndReleaseOpenPort();
    webdevServer = await WebdevServer.start(['test:$port']);

    // We don't have a good way of knowing when the `webdev serve` process has
    // started listening on the port, so we send a request periodically until it
    // succeeds. If the code under test is broken, this test will timeout.
    http.Response response;
    while (true) {
      try {
        response = await http.get('http://localhost:${port}/web/index.dart');
      } catch (_) {
        await Future.delayed(Duration(milliseconds: 250));
        continue;
      }
      if (response?.statusCode == 200) {
        break;
      }
    }

    expect(response.statusCode, 200);
    expect(response.body, isNotEmpty);
  });
}
