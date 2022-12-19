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
import 'dart:io';

import 'package:test/test.dart';

Future<Null> activateWebdev(String constraint) async {
  final process = await Process.start(
    'dart',
    ['pub', 'global', 'activate', 'webdev', constraint],
    mode: ProcessStartMode.inheritStdio,
  );
  expect(await process.exitCode, 0,
      reason: 'Failed to global activate webdev $constraint.');
  expect(isWebdevGlobalActivated(), isTrue,
      reason: "Webdev should be globally active, but isn't.");
}

Future<Null> deactivateWebdev() async {
  if (!isWebdevGlobalActivated()) {
    return;
  }
  final process = await Process.start(
    'dart',
    ['pub', 'global', 'deactivate', 'webdev'],
    mode: ProcessStartMode.inheritStdio,
  );
  expect(await process.exitCode, 0,
      reason: 'Failed to global deactivate webdev.');
  expect(isWebdevGlobalActivated(), isFalse,
      reason: 'Webdev should not be globally active, but is.');
}

final webdevGlobalPattern = RegExp(r'webdev [\d.]+');

bool isWebdevGlobalActivated() {
  final procResult = Process.runSync(
    'dart',
    ['pub', 'global', 'list'],
    stdoutEncoding: utf8,
  );
  return procResult.stdout
      .toString()
      .split('\n')
      .any(webdevGlobalPattern.hasMatch);
}
