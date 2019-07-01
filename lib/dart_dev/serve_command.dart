import 'package:args/command_runner.dart';

import '../src/dart_dev_commands.dart';

export '../src/dart_dev_commands.dart' show WebdevProxyServeConfig;

Iterable<Command<int>> buildWebdevProxyServeCommands({
  WebdevProxyServeConfig serveConfig,
}) => [
  HiddenWebdevProxyServeCommand(),
  WebdevProxyServeCommand(serveConfig),
];