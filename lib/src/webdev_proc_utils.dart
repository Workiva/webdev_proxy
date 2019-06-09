import 'dart:convert';
import 'dart:io';

import 'package:io/ansi.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:webdev_proxy/src/logging.dart';

final webdevCompatibility = new VersionConstraint.parse('>=1.0.1 <3.0.0');

ProcessResult cachedWebdevVersionResult;
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

Future<int> startWebdevServe(List<String> args) async {
  final webdevArgs = ['global', 'run', 'webdev', 'serve', ...args];
  log.fine('Running `pub ${webdevArgs.join(' ')}');
  final process = await Process.start(
    'pub',
    webdevArgs,
    mode: ProcessStartMode.inheritStdio,
  );
  return process.exitCode;
}
