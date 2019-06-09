import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

void activateWebdev(String constraint) {
  final procResult = Process.runSync(
    'pub',
    ['global', 'activate', 'webdev', constraint],
  );
  expect(procResult.exitCode, 0,
      reason: 'Failed to global activate webdev $constraint:\n'
          '${procResult.stdout}');
  expect(isWebdevGlobalActivated(), isTrue,
      reason: "Webdev should be globally active, but isn't.");
}

void deactivateWebdev() {
  if (!isWebdevGlobalActivated()) {
    return;
  }
  final procResult = Process.runSync(
    'pub',
    ['global', 'deactivate', 'webdev'],
  );
  expect(procResult.exitCode, 0,
      reason: 'Failed to global deactivate webdev:\n'
          '${procResult.stdout}');
  expect(isWebdevGlobalActivated(), isFalse,
      reason: 'Webdev should not be globally active, but is.');
}

bool isWebdevGlobalActivated() {
  final procResult = Process.runSync(
    'pub',
    ['global', 'list'],
    stdoutEncoding: utf8,
  );
  return procResult.stdout.toString().contains('webdev');
}
