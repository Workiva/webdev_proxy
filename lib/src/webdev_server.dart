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
import 'dart:io';

import 'package:webdev_proxy/src/logging.dart';

/// A simple abstraction over a `webdev serve ...` process.
class WebdevServer {
  /// The `webdev serve ...` process.
  final Process _process;

  WebdevServer._(this._process);

  /// Returns a Future which completes with the exit code of the underlying
  /// `webdev serve` process.
  Future<int> get exitCode => _process.exitCode;

  /// Permanently stops this proxy server from listening for new connections and
  /// closes all active connections immediately.
  Future<Null> close() async {
    _process.kill();
    await _process.exitCode;
  }

  /// Starts a `webdev serve` process with the given [args] and returns a
  /// [WebdevServer] abstraction over said process.
  static Future<WebdevServer> start(List<String> args) async {
    final webdevArgs = ['global', 'run', 'webdev', 'serve', ...args];
    log.fine('Running `pub ${webdevArgs.join(' ')}');
    final process = await Process.start(
      'pub',
      webdevArgs,
      mode: ProcessStartMode.inheritStdio,
    );
    return WebdevServer._(process);
  }
}
