import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:io/ansi.dart';
import 'package:pedantic/pedantic.dart';

import 'package:webdev_proxy/src/command_utils.dart';
import 'package:webdev_proxy/src/logging.dart';
import 'package:webdev_proxy/src/proxy_server.dart';
import 'package:webdev_proxy/src/webdev_arg_utils.dart';
import 'package:webdev_proxy/src/webdev_proc_utils.dart';

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
  String get usageFooter {
    if (_missingWebdev) {
      return red.wrap(
        'This command requires that `webdev` be activated globally.\n'
        'Please run the following:\n'
        '\tpub global activate webdev $webdevCompatibility',
      );
    } else if (!_hasCompatibleWebdev) {
      return red.wrap(
        'This command is only compatible with `webdev $webdevCompatibility`,\n'
        'but you currently have v${getGlobalWebdevVersion()} active.\n'
        'Please run the following to activate a compatible version:\n'
        '\tpub global activate webdev $webdevCompatibility',
      );
    }
    return null;
  }

  @override
  String get name => 'serve';

  bool get _hasCompatibleWebdev =>
      webdevCompatibility.allows(getGlobalWebdevVersion());

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

  @override
  Future<int> run() async {
    // This command doesn't allow overriding the formatter inputs or specifying
    // any arguments at the dart_dev level. Instead arguments should be passed
    // after the `--` separator.
    //
    // Here we validate that [argResults.rest] is exactly equal to all the
    // arguments after the `--`.
    assertNoPositionalArgsBeforeSeparator(name, argResults, usageException);

    // Parse the hostname to serve each dir on (defaults to 0.0.0.0)
    final hostname = parseHostname(argResults.rest);

    // Parse the directory:port mappings that will be used by the proxy servers.
    // Each proxy will be mapped to a `webdev serve` instance on another port.
    final portsToServeByDir = parseDirectoryArgs(argResults.rest);
    var baseWebdevPort = 9111;
    final portsToProxyByDir = {
      for (final dir in portsToServeByDir.keys) '$dir': baseWebdevPort++,
    };

    // Start the underlying `webdev serve` process.
    final webdevExitCode = startWebdevServe([
      ...argResults.rest,
      if (hostname != 'localhost') '--hostname=$hostname',
      for (final dir in portsToProxyByDir.keys)
        '$dir:${portsToProxyByDir[dir]}',
    ]);

    // Start a proxy server for each directory.
    final proxies =
        await Future.wait(portsToServeByDir.keys.map((dir) => ProxyServer.start(
              dir: dir,
              hostname: hostname,
              portToProxy: portsToProxyByDir[dir],
              portToServe: portsToServeByDir[dir],
              rewrite404s: argResults[rewrite404sFlag] == true,
            )));

    // Stop proxies and exit if webdev exits.
    unawaited(webdevExitCode.then((code) async {
      log.info('Terminating proxy because webdev serve exited.\n');
      await Future.wait(proxies.map((proxy) => proxy.close()));
      exit(code);
    }));

    // Stop proxies and exit on user interrupt.
    unawaited(ProcessSignal.sigint.watch().first.then((_) async {
      await Future.wait(proxies.map((proxy) => proxy.close()));
      exit(0);
    }));

    return Completer<int>().future;
  }
}
