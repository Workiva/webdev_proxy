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

import 'package:args/command_runner.dart';
import 'package:io/ansi.dart';
import 'package:io/io.dart' show ExitCode;
import 'package:path/path.dart' as p;
import 'package:shelf/shelf.dart';

import 'command_runner.dart';
import 'dart_tool_cache.dart';
import 'ensure_process_exit.dart';

typedef _HandlersGetter = Iterable<Handler> Function();
typedef _MiddlewareGetter = Iterable<Middleware> Function();

const _customWebdevProxyDartPath = 'tool/webdev_proxy.dart';
final _customEntrypointPath = p.join(cacheDirPath, 'custom_executable.dart');
final _customEntrypoint = File(_customEntrypointPath);
final _relativeWebdevProxyDartPath = p.relative(
  p.absolute(_customWebdevProxyDartPath),
  from: p.absolute(p.dirname(_customEntrypointPath)),
);
final _customEntrypointContents = '''
import 'dart:io';

import 'package:webdev_proxy/src/executable.dart' as executable;
import '$_relativeWebdevProxyDartPath' as custom_webdev_proxy;

void main(List<String> args) async {
  exit(await executable.runWithConfig(args,
      () => custom_webdev_proxy.handlers,
      () => custom_webdev_proxy.middleware));
}
''';

/// Runs the [WebdevProxy] command-runner and returns its exit code.
///
/// Also catches and prints [UsageException]s.
Future<int> run(List<String> args) async {
  if (File(_customWebdevProxyDartPath).existsSync()) {
    return runViaCustomEntrypoint(args);
  }
  return _run(args);
}

Future<int> runWithConfig(List<String> args, _HandlersGetter handlersGetter,
    _MiddlewareGetter middlewareGetter) async {
  Iterable<Handler> customHandlers;
  Iterable<Middleware> customMiddleware;
  try {
    customHandlers = handlersGetter();
  } catch (_) {}
  try {
    customMiddleware = middlewareGetter();
  } catch (_) {}
  return _run(args,
      customHandlers: customHandlers, customMiddleware: customMiddleware);
}

Future<int> runViaCustomEntrypoint(List<String> args) async {
  _generateCustomEntrypoint();
  final process = await Process.start(
      Platform.executable,
      [
        _customEntrypointPath,
        ...args,
      ],
      mode: ProcessStartMode.inheritStdio);
  ensureProcessExit(process);
  return process.exitCode;
}

void _generateCustomEntrypoint() {
  if (_shouldWriteCustomEntrypoint()) {
    createCacheDir();
    _customEntrypoint.writeAsStringSync(_customEntrypointContents);
  }
}

bool _shouldWriteCustomEntrypoint() {
  return !_customEntrypoint.existsSync() ||
      _customEntrypoint.readAsStringSync() != _customEntrypointContents;
}

Future<int> _run(List<String> args,
    {Iterable<Handler> customHandlers,
    Iterable<Middleware> customMiddleware}) async {
  try {
    // Explicitly `await` here so we can catch any usage exceptions.
    return await WebdevProxy(
            customHandlers: customHandlers, customMiddleware: customMiddleware)
        .run(args);
  } on UsageException catch (e) {
    print(red.wrap(e.message));
    print('');
    print(e.usage);
    return ExitCode.usage.code;
  }
}
