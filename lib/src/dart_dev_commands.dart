
import 'package:args/command_runner.dart';
import 'package:dart_dev/command_utils.dart';
import 'package:logging/logging.dart';

import 'serve_command.dart';

final _log = Logger('WebdevProxyServe');

class HiddenWebdevProxyServeCommand extends ServeCommand {
  @override
  String get name => '_webdev_proxy_serve';
  
  @override
  String get description => '';

  @override
  bool get hidden => true;
}

class WebdevProxyServeCommand extends Command<int> {
  final WebdevProxyServeConfig config;

  WebdevProxyServeCommand([WebdevProxyServeConfig config]) : config = config ?? WebdevProxyServeConfig();

  @override
  String get name => config.commandName ?? 'webdev_proxy_serve';

  @override
  String get description => config.description ?? ServeCommand.defaultDescription;

  @override
  bool get hidden => config?.hidden ?? false;

  @override
  Future<int> run() async {
    final webdevArgs = config.webdevArgs ?? [];
    return runner.run([
      '_webdev_proxy_serve',
      ...takeArgsBeforeSeparator(argResults.arguments).skip(1),
      if (webdevArgs.isNotEmpty) ...[
        '--',
        ...config.webdevArgs
      ],
      ...takeArgsAfterSeparator(argResults.arguments),
    ]);
  }
}

class WebdevProxyServeConfig {
  WebdevProxyServeConfig({
    this.commandName,
    this.description,
    this.hidden,
    this.webdevArgs,
  });
  
  final String commandName;
  final String description;
  final bool hidden;
  final List<String> webdevArgs;

  WebdevProxyServeConfig merge(WebdevProxyServeConfig other) => WebdevProxyServeConfig(
    commandName: other?.commandName ?? commandName,
    description: other?.description ?? description,
    hidden: other?.hidden ?? hidden,
    webdevArgs: other?.webdevArgs ?? webdevArgs,
  );
}