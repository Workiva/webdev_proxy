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

final _defaultWebDirs = const ['web'];
final _dirPattern = RegExp(r'^(\w+)(?::(\d+))?$');

/// Returns a mapping of directories to ports parsed from command-line [args] in
/// the form of `<directory>:<port>`.
///
/// If no mappings are specified in [args], the default mapping of web:8080 is
/// returned.
Map<String, int> parseDirectoryArgs(List<String> args) {
  final result = <String, int>{};
  var basePort = 8080;
  final dirArgs = args.where((_dirPattern.hasMatch));
  if (dirArgs.isEmpty) {
    for (final dir in _defaultWebDirs) {
      result[dir] = basePort++;
    }
  } else {
    for (final arg in dirArgs) {
      final splitOption = arg.split(':');
      if (splitOption.length == 2) {
        result[splitOption.first] = int.parse(splitOption.last);
      } else {
        result[arg] = basePort++;
      }
    }
  }
  return result;
}

/// Returns the value of the `--hostname` option from a list of command-line
/// [args] only if it is specified.
///
/// Otherwise, returns a default of `'localhost'`.
String parseHostname(List<String> args) {
  for (var i = 0; i < args.length; i++) {
    if (!args[i].startsWith('--hostname')) {
      continue;
    }
    if (args[i].contains('=')) {
      // --hostname=<value>
      return args[i].split('=')[1];
    }
    if (i + 1 < args.length && !args[i + 1].startsWith('-')) {
      // --hostname <value>
      return args[i + 1];
    }
  }
  return 'localhost';

  // TODO: Use when webdev `--hostname=any` support is released
  // HttpMultiServer supports `any` as a more flexible localhost.
  // return 'any';
}
