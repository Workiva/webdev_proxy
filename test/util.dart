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
}

void deactivateWebdev() {
  final procResult = Process.runSync(
    'pub',
    ['global', 'deactivate', 'webdev'],
  );
  expect(procResult.exitCode, 0,
      reason: 'Failed to global deactivate webdev:\n'
          '${procResult.stdout}');
}
