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

import 'package:io/ansi.dart';
import 'package:meta/meta.dart';
import 'package:pub_semver/pub_semver.dart';

/// The range of `webdev` versions with which this `webdev_proxy` package is
/// compatible.
final webdevCompatibility = VersionConstraint.parse('>=1.0.1 <3.0.0');

@visibleForTesting
ProcessResult cachedWebdevVersionResult;

/// Returns the version of the `webdev` package that is currently globally
/// activated, or `null` if it is not activated.
Version getGlobalWebdevVersion() {
  cachedWebdevVersionResult ??= Process.runSync(
    'pub',
    ['global', 'run', 'webdev', '--version'],
    stdoutEncoding: utf8,
  );
  if (cachedWebdevVersionResult.exitCode != 0) {
    return null;
  }
  return Version.parse(cachedWebdevVersionResult.stdout.toString().trim());
}

/// Prints the output from `webdev help serve` with a header that explains how
/// it applies in the context of the `webdev_proxy serve` executable.
///
/// Returns the exit code from running `webdev help serve`.
Future<int> printWebdevServeHelp() async {
  print(
    yellow.wrap('\n'
        'You may use any of the following options supported by `webdev serve` by '
        'passing them after the `--` separator.\n\n'
        'webdev serve --help:\n'
        '====================\n'),
  );
  final process = await Process.start(
    'pub',
    ['global', 'run', 'webdev', 'help', 'serve'],
    mode: ProcessStartMode.inheritStdio,
  );
  return process.exitCode;
}
