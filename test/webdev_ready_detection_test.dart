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
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:test/test.dart';
import 'package:webdev_proxy/src/port_utils.dart';
import 'package:webdev_proxy/src/webdev_proc_utils.dart';
import 'package:webdev_proxy/src/webdev_server.dart';

import 'util.dart';

// Matches the build-complete patterns that build_runner emits to webdev stdout.
final _buildCompletePattern =
    RegExp(r'Built with build_runner|Failed to build with build_runner');

// Strips ANSI escape sequences so output is readable in test logs.
String _stripAnsi(String s) =>
    s.replaceAll(RegExp(r'\x1b\[[0-9;]*[a-zA-Z]'), '');

void main() {
  setUpAll(() async {
    await activateWebdev(webdevCompatibility.toString());
  });

  group('WebdevServer', () {
    late WebdevServer webdevServer;

    tearDown(() async {
      await webdevServer.close();
    });

    test('stdoutLines emits build-complete signal before HTTP server responds',
        () async {
      final port = await findUnusedPort();
      webdevServer = await WebdevServer.start(['test:$port']);

      final allLines = <String>[];
      webdevServer.stdoutLines.listen((line) => allLines.add(line));

      String? matchedLine;
      try {
        matchedLine = await webdevServer.stdoutLines
            .firstWhere(_buildCompletePattern.hasMatch)
            .timeout(const Duration(seconds: 90));
      } on TimeoutException {
        fail('Timed out waiting for build-complete signal.\n'
            'Lines seen:\n'
            '${allLines.map(_stripAnsi).map((l) => '  $l').join('\n')}');
      } on StateError {
        fail('Build-complete signal never appeared — webdev exited early.\n'
            'Lines seen:\n'
            '${allLines.map(_stripAnsi).map((l) => '  $l').join('\n')}');
      }

      expect(_stripAnsi(matchedLine), matches(_buildCompletePattern));

      // Verify the server is also HTTP-responsive at this point.
      final response = await http
          .get(Uri.parse('http://localhost:$port/'))
          .timeout(const Duration(seconds: 10));
      expect(response.statusCode, isNot(equals(0)));
    });
  });

  group('ServeCommand', () {
    late Process proxyProcess;

    tearDown(() async {
      proxyProcess.kill();
      await proxyProcess.exitCode;
    });

    test('outputs "Succeeded after" once the initial build completes',
        () async {
      final port = await findUnusedPort();
      proxyProcess = await Process.start(
        'dart',
        ['bin/webdev_proxy.dart', 'serve', '--', 'test:$port'],
        mode: ProcessStartMode.normal,
      );

      final stdoutLines = proxyProcess.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .asBroadcastStream();

      // Drain stderr so the process doesn't block.
      proxyProcess.stderr.drain<void>();

      final allLines = <String>[];
      stdoutLines.listen((line) => allLines.add(line));

      String? matchedLine;
      try {
        matchedLine = await stdoutLines
            .firstWhere((line) => line.contains('Succeeded after'))
            .timeout(const Duration(seconds: 90));
      } on TimeoutException {
        fail('Timed out waiting for "Succeeded after" in proxy output.\n'
            'Lines seen:\n'
            '${allLines.map(_stripAnsi).map((l) => '  $l').join('\n')}');
      } on StateError {
        fail('"Succeeded after" never appeared — proxy exited early.\n'
            'Lines seen:\n'
            '${allLines.map(_stripAnsi).map((l) => '  $l').join('\n')}');
      }

      expect(_stripAnsi(matchedLine), contains('Succeeded after'));
    });
  });
}
