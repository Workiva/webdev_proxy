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
import 'dart:io';

import 'package:webdev_proxy/src/logging.dart';

/// A simple abstraction over a `webdev serve ...` process.
class WebdevServer {
  /// The `webdev serve ...` process.
  final Process _process;

  /// A broadcast stream of raw stdout bytes from the `webdev serve` process.
  ///
  /// Pipe directly to [stdout] to preserve webdev's native terminal output,
  /// including ANSI escape sequences and carriage-return-based line rewrites.
  final Stream<List<int>> stdoutBytes;

  /// A broadcast stream of lines from the `webdev serve` process stdout.
  ///
  /// Useful for detecting build lifecycle events such as
  /// `'Built with build_runner'` (success) or
  /// `'Failed to build with build_runner'` (failure).
  final Stream<String> stdoutLines;

  WebdevServer._(this._process, this.stdoutBytes, this.stdoutLines);

  /// Returns a Future which completes with the exit code of the underlying
  /// `webdev serve` process.
  Future<int> get exitCode => _process.exitCode;

  /// Permanently stops this proxy server from listening for new connections and
  /// closes all active connections immediately.
  Future<void> close() async {
    _process.kill();
    await _process.exitCode;
  }

  /// Starts a `webdev serve` process with the given [args] and returns a
  /// [WebdevServer] abstraction over said process.
  static Future<WebdevServer> start(List<String> args) async {
    final webdevArgs = [
      'pub',
      'global',
      'run',
      'webdev',
      'serve',
      ...args,
    ];
    log.fine('Running `dart ${webdevArgs.join(' ')}');
    final process = await Process.start(
      'dart',
      webdevArgs,
      mode: ProcessStartMode.normal,
    );

    // Forward stderr so error messages remain visible.
    process.stderr.listen((data) => stderr.add(data));

    // Fork stdout at the byte level into a broadcast stream. The listen() call
    // here is essential: it drains the process stdout pipe (preventing
    // backpressure deadlock) regardless of whether anyone subscribes.
    final bytesController = StreamController<List<int>>.broadcast();
    process.stdout.listen(bytesController.add,
        onDone: bytesController.close, cancelOnError: false);

    // Derive a text-line stream from the same bytes for signal detection.
    final linesController = StreamController<String>.broadcast();
    bytesController.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(linesController.add,
            onDone: linesController.close, cancelOnError: false);

    return WebdevServer._(
        process, bytesController.stream, linesController.stream);
  }
}
