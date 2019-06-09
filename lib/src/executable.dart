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

import 'package:args/command_runner.dart';
import 'package:io/ansi.dart';
import 'package:io/io.dart' show ExitCode;

import 'package:webdev_proxy/src/command_runner.dart';

/// Runs the [WebdevProxy] command-runner and returns its exit code.
///
/// Also catches and prints [UsageException]s.
Future<int> run(List<String> args) async {
  try {
    // Explicitly `await` here so we can catch any usage exceptions.
    return await WebdevProxy().run(args);
  } on UsageException catch (e) {
    print(red.wrap(e.message));
    print('');
    print(e.usage);
    return ExitCode.usage.code;
  }
}
