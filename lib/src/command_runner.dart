import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:logging/logging.dart';

import 'package:webdev_proxy/src/logging.dart';
import 'package:webdev_proxy/src/serve_command.dart';

class WebdevProxy extends CommandRunner<int> {
  static const verboseFlag = 'verbose';

  WebdevProxy()
      : super('webdev_proxy',
            'A simple dart proxy for `webdev serve` (uses the `shelf_proxy` package).') {
    addCommand(new ServeCommand());
    argParser.addFlag(verboseFlag, abbr: 'v', help: 'Enable verbose output.');
  }

  @override
  Future<int> run(Iterable<String> args) async {
    // The help command returns null, so return success code in that case.
    return await super.run(args) ?? 0;
  }

  @override
  Future<int> runCommand(ArgResults topLevelResults) async {
    final verbose = topLevelResults[verboseFlag] == true;
    Logger.root.level = verbose ? Level.ALL : Level.INFO;
    Logger.root.onRecord.listen(stdIOLogListener(verbose: verbose));
    return super.runCommand(topLevelResults);
  }
}
