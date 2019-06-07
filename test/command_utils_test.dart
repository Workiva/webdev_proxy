@TestOn('vm')
import 'package:args/args.dart';
import 'package:test/test.dart';

import 'package:webdev_proxy/src/command_utils.dart';

void main() {
  group('assertNoPositionalArgsBeforeSeparator', () {
    final argParser = ArgParser()..addCommand('command');
    String capturedUsageException;
    void usageException(String msg) => capturedUsageException = msg;

    tearDown(() {
      capturedUsageException = null;
    });

    group('does not report usage exception if', () {
      test('if rest args are empty', () {
        final argResults = argParser.parse(['command']);
        assertNoPositionalArgsBeforeSeparator(
            'serve', argResults.command, usageException);
        expect(capturedUsageException, isNull);
      });

      test('if expected flag is parsed', () {
        argParser.addFlag('flag');
        final argResults = argParser.parse(['command', '--flag']);
        assertNoPositionalArgsBeforeSeparator(
            'serve', argResults.command, usageException);
        expect(capturedUsageException, isNull);
      });

      test('if args are only passed after -- separator', () {
        final argResults = argParser.parse(['command', '--', 'after']);
        assertNoPositionalArgsBeforeSeparator(
            'serve', argResults.command, usageException);
        expect(capturedUsageException, isNull);
      });
    });

    group('reports usage exception if', () {
      test('-- separator is missing', () {
        final argResults = argParser.parse(['command', 'foo']);
        assertNoPositionalArgsBeforeSeparator(
            'serve', argResults.command, usageException);
        expect(capturedUsageException, isNotNull);
      });

      test('args exist before -- separator', () {
        final argResults =
            argParser.parse(['command', 'before', '--', 'after']);
        assertNoPositionalArgsBeforeSeparator(
            'serve', argResults.command, usageException);
        expect(capturedUsageException, isNotNull);
      });
    });
  });
}
