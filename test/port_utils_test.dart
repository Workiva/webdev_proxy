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

import 'package:test/test.dart';

import 'package:webdev_proxy/src/port_utils.dart';

void main() {
  group('findAndReleaseOpenPort()', () {
    test('should return an open port', () async {
      final port = await findAndReleaseOpenPort();
      ServerSocket socket;
      try {
        socket = await ServerSocket.bind('localhost', port);
      } catch (e) {
        fail('Expected $port to be open for binding.\n$e');
      }
      expect(socket.port, port);
      await socket.close();
    });

    test('should return distinct ports when called multiple times', () async {
      final port1 = await findAndReleaseOpenPort();
      final port2 = await findAndReleaseOpenPort();
      expect(port1, isNot(port2), reason: 'Ports should be distinct.');
    });
  });
}
