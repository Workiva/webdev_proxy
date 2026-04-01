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
final _dirPattern = RegExp(
    // Matches and captures any directory path, e.g. `web` or `test/nested/dir/`
    r'^([\w/]+)'
    // Optional non-capturing group since webdev allows for the ports to be omitted
    r'(?:'
    // Matches and captures any port, e.g. `:8080` or `:9001`
    r':(\d+)'
    // Ends the optional non-capturing group
    r'){0,2}$');

class ParsedDirectoryPorts {
  final String directory;
  final int? proxyPort;
  final int servePort;
  ParsedDirectoryPorts(
      {required this.directory, this.proxyPort, required this.servePort});
}

/// Returns a mapping of directories to ports parsed from command-line [args] in
/// the form of `<directory>:<port>`.
///
/// If no mappings are specified in [args], the default mapping of web:8080 is
/// returned.
ParseDirectoryArgsResults parseDirectoryArgs(List<String> args) {
  final ports = <ParsedDirectoryPorts>[];
  final remainingArgs = <String>[];
  var basePort = 8080;
  for (final arg in args) {
    if (!_dirPattern.hasMatch(arg)) {
      remainingArgs.add(arg);
    } else {
      final splitOption = arg.split(':');
      if (splitOption.length == 3) {
        ports.add(ParsedDirectoryPorts(
            directory: splitOption[0],
            proxyPort: int.parse(splitOption[1]),
            servePort: int.parse(splitOption[2])));
      } else if (splitOption.length == 2) {
        ports.add(ParsedDirectoryPorts(
            directory: splitOption.first,
            servePort: int.parse(splitOption.last)));
      } else {
        ports
            .add(ParsedDirectoryPorts(directory: arg, servePort: basePort++));
      }
    }
  }
  return ParseDirectoryArgsResults(ports, remainingArgs);
}

class ParseDirectoryArgsResults {
  final List<ParsedDirectoryPorts> ports;
  final List<String> remainingArgs;
  ParseDirectoryArgsResults(this.ports, this.remainingArgs);
}

/// Returns the value of the `--hostname` option from a list of command-line
/// [args] only if it is specified.
///
/// Otherwise, returns a default of `'localhost'`.
ParseHostnameResults parseHostname(List<String> args) {
  var hostname = 'localhost';
  final remainingArgs = <String>[];
  var skipNext = false;
  for (var i = 0; i < args.length; i++) {
    if (skipNext) {
      skipNext = false;
      continue;
    } else if (!args[i].startsWith('--hostname')) {
      remainingArgs.add(args[i]);
    } else if (args[i].contains('=')) {
      // --hostname=<value>
      hostname = args[i].split('=')[1];
    } else if (i + 1 < args.length && !args[i + 1].startsWith('-')) {
      // --hostname <value>
      hostname = args[i + 1];
      skipNext = true;
    }
  }
  return ParseHostnameResults(hostname, remainingArgs);

  // TODO: Use when webdev `--hostname=any` support is released
  // HttpMultiServer supports `any` as a more flexible localhost.
  // return 'any';
}

class ParseHostnameResults {
  final String hostname;
  final List<String> remainingArgs;
  ParseHostnameResults(this.hostname, this.remainingArgs);
}
