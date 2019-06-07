import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:io/ansi.dart';
import 'package:io/io.dart' show ExitCode;

import 'package:webdev_proxy/src/command_runner.dart';

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
