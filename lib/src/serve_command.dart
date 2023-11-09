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
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:io/ansi.dart';
import 'package:io/io.dart';

import 'package:webdev_proxy/src/command_runner.dart';
import 'package:webdev_proxy/src/command_utils.dart';
import 'package:webdev_proxy/src/logging.dart';
import 'package:webdev_proxy/src/port_utils.dart';
import 'package:webdev_proxy/src/webdev_arg_utils.dart';
import 'package:webdev_proxy/src/webdev_proc_utils.dart';
import 'package:webdev_proxy/src/webdev_proxy_server.dart';
import 'package:webdev_proxy/src/webdev_server.dart';

/// The `serve` command for the [WebdevProxy] command-runner.
///
/// Runs `webdev serve` behind a simple HTTP proxy.
class ServeCommand extends Command<int> {
  static const rewrite404sFlag = 'rewrite-404s';

  ServeCommand() {
    argParser.addFlag(rewrite404sFlag,
        defaultsTo: true,
        help: 'Rewrite every request that returns a 404 to /index.html');
  }

  @override
  String get description =>
      'Run `webdev serve` (a local web development server) behind a proxy that '
      'supports HTML5 routing by rewriting not-found requests to index.html.';

  @override
  String get invocation =>
      '${super.invocation.replaceFirst(' [arguments]', '')} '
      '[-- [webdev serve arguments]]';

  @override
  String? get usageFooter => _webdevCompatibilityHelp;

  @override
  String get name => 'serve';

  bool get _canUseWebdev => !_missingWebdev && _hasCompatibleWebdev;

  bool get _hasCompatibleWebdev =>
      webdevCompatibility.allows(getGlobalWebdevVersion()!);

  bool get _missingWebdev => getGlobalWebdevVersion() == null;

  @override
  void printUsage() {
    super.printUsage();

    // We want to append the `webdev help serve` output to our own usage output
    // since we allow the passing of `webdev serve` args after the `--`
    // separator. However, we do it here instead of in [usageFooter] so that we
    // can run the process with [ProcessStartMode.inheritStdio], resulting in a
    // better output since it is then able to detect the tty.
    if (_hasCompatibleWebdev) {
      printWebdevServeHelp();
    }
  }

  String? get _webdevCompatibilityHelp {
    if (_missingWebdev) {
      return red.wrap(
        'This command requires that `webdev` be activated globally.\n'
        'Please run the following:\n'
        '\tdart pub global activate webdev "$webdevCompatibility"',
      );
    } else if (!_hasCompatibleWebdev) {
      return red.wrap(
        'This command is only compatible with `webdev $webdevCompatibility`, '
        'but you currently have webdev ${getGlobalWebdevVersion()} active.\n'
        'Please run the following to activate a compatible version:\n'
        '\tdart pub global activate webdev "$webdevCompatibility"',
      );
    }
    return null;
  }

  @override
  Future<int> run() async {
    if (!_canUseWebdev) {
      print(_webdevCompatibilityHelp);
      return ExitCode.usage.code;
    }

    // This command doesn't allow specifying any arguments at the webdev_proxy
    // level. Instead arguments should be passed to the `webdev` process by
    // passing them after the `--` separator.
    //
    // To enforce this, we validate that [argResults.rest] is exactly equal to
    // all the arguments after the `--`.
    assertNoPositionalArgsBeforeSeparator(name, argResults!, usageException);

    final exitCodeCompleter = Completer<int>();
    var interruptReceived = false;
    final proxies = <WebdevProxyServer>[];
    var proxiesFailed = false;
    StreamSubscription? sigintSub;
    WebdevServer? webdevServer;

    void shutDown(int code) async {
      await Future.wait([
        if (sigintSub != null) sigintSub.cancel(),
        if (webdevServer != null) webdevServer.close(),
        ...proxies.map((proxy) => proxy.close()),
      ]);
      if (!exitCodeCompleter.isCompleted) {
        exitCodeCompleter.complete(code);
      }
    }

    // Shutdown everything and exit on user interrupt.
    sigintSub = ProcessSignal.sigint.watch().listen((_) {
      interruptReceived = true;
      log.info('Interrupt received, exiting.\n');
      shutDown(ExitCode.success.code);
    });

    // Parse the hostname to serve each dir on (defaults to 0.0.0.0)
    final hostnameResults = parseHostname(argResults!.rest);
    final hostname = hostnameResults.hostname;
    final remainingArgs = hostnameResults.remainingArgs;

    // Parse the directory:port mappings that will be used by the proxy servers.
    // Each proxy will be mapped to a `webdev serve` instance on another port.
    final portsToServeByDir = parseDirectoryArgs(argResults!.rest);

    // Find open ports for each of the directories to be served by webdev.
    final portsToProxyByDir = {
      for (final dir in portsToServeByDir.keys) dir: await findUnusedPort()
    };

    // Start the underlying `webdev serve` process.
    webdevServer = await WebdevServer.start([
      if (hostname != 'localhost') '--hostname=$hostname',
      ...remainingArgs,
      for (final dir in portsToServeByDir.keys)
        '$dir:${portsToProxyByDir[dir]}',
    ]);

    // Stop proxies and exit if webdev exits.
    unawaited(webdevServer.exitCode.then((code) {
      if (!interruptReceived && !proxiesFailed) {
        log.info('Terminating proxy because webdev serve exited.\n');
        shutDown(code);
      }
    }));

    // Start a proxy server for each directory.
    for (final dir in portsToServeByDir.keys) {
      try {
        proxies.add(await WebdevProxyServer.start(
          dir: dir,
          hostname: hostname,
          portToProxy: portsToProxyByDir[dir],
          portToServe: portsToServeByDir[dir]!,
          rewrite404s: argResults![rewrite404sFlag] == true,
        ));
      } catch (e, stackTrace) {
        proxiesFailed = true;
        log.severe(
            'Failed to start proxy server on port ${portsToServeByDir[dir]}',
            e,
            stackTrace);
        shutDown(ExitCode.unavailable.code);
        break;
      }
    }

    return exitCodeCompleter.future;
  }
}
