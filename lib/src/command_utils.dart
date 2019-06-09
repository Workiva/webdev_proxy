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

import 'package:args/args.dart';

/// Calls [usageException] if any positional args are found in [argResults]
/// before the `--` separator, as they are disallowed.
void assertNoPositionalArgsBeforeSeparator(
  String command,
  ArgResults argResults,
  void usageException(String msg),
) {
  if (argResults.rest.isEmpty) {
    return;
  }

  void throwUsageException() {
    usageException(
      'webdev_proxy $command does not support positional args before the `--`'
      'separator, which should separate proxy args from `webdev` args.',
    );
  }

  final separatorPos = argResults.arguments.indexOf('--');
  if (separatorPos < 0) {
    throwUsageException();
    return;
  }
  final expectedRest = argResults.arguments.skip(separatorPos + 1).toList();
  if (argResults.rest.length != expectedRest.length) {
    throwUsageException();
    return;
  }
  for (var i = 0; i < argResults.rest.length; i++) {
    if (expectedRest[i] != argResults.rest[i]) {
      throwUsageException();
    }
  }
}
