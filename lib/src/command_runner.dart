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
import 'package:args/command_runner.dart';
import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart';

import 'package:webdev_proxy/src/logging.dart';
import 'package:webdev_proxy/src/serve_command.dart';

/// Command runner for the `webdev_proxy` executable.
class WebdevProxy extends CommandRunner<int> {
  static const verboseFlag = 'verbose';

  WebdevProxy({Iterable<Handler> customHandlers})
      : super('webdev_proxy',
            'A simple dart proxy for `webdev serve` (uses the `shelf_proxy` package).') {
    addCommand(ServeCommand(customHandlers: customHandlers));
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
