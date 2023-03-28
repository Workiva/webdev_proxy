import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:webdev_proxy/src/port_utils.dart';
import 'package:webdriver/io.dart' as wd;

const chromeDriverPort = 4444;
const chromeDriverUrlBase = 'wd/hub';

Future<void> startChromeDriver() async {
  try {
    final chromeDriver = await Process.start(
        'chromedriver', ['--port=4444', '--url-base=wd/hub']);
    addTearDown(() {
      if (!chromeDriver.kill()) {
        chromeDriver.kill(ProcessSignal.sigkill);
      }
    });

    // On windows this takes a while to boot up, wait for the first line
    // of stdout as a signal that it is ready.
    final stdOutLines = chromeDriver.stdout
        .transform(utf8.decoder)
        .transform(LineSplitter())
        .asBroadcastStream();

    final stdErrLines = chromeDriver.stderr
        .transform(utf8.decoder)
        .transform(LineSplitter())
        .asBroadcastStream();

    stdOutLines.listen((line) => print('ChromeDriver stdout: $line'));
    stdErrLines.listen((line) => print('ChromeDriver stderr: $line'));

    await stdOutLines.first;
  } catch (e) {
    throw StateError(
        'Could not start ChromeDriver. Is it installed?\nError: $e');
  }
}

Future<wd.WebDriver> createWebDriver() async {
  final debugPort = await findUnusedPort();
  final capabilities = wd.Capabilities.chrome
    ..addAll({
      wd.Capabilities.chromeOptions: {
        'args': [
          'remote-debugging-port=$debugPort',
          '--headless',
        ]
      }
    });
  final webDriver = await wd.createDriver(
      spec: wd.WebDriverSpec.JsonWire,
      desired: capabilities,
      uri: Uri.parse(
          'http://127.0.0.1:$chromeDriverPort/$chromeDriverUrlBase/'));
  addTearDown(webDriver.quit);
  return webDriver;
}
