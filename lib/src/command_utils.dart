import 'package:args/args.dart';

void assertNoPositionalArgsBeforeSeparator(
  String command,
  ArgResults argResults,
  void usageException(String msg),
) {
  if (argResults.rest.isEmpty) {
    return;
  }

  void throwUsageException() {
    usageException(
      'webdev_proxy $command does not support positional args before the `--`'
      'separator, which should separate proxy args from `webdev` args.',
    );
  }

  final separatorPos = argResults.arguments.indexOf('--');
  if (separatorPos < 0) {
    throwUsageException();
    return;
  }
  final expectedRest = argResults.arguments.skip(separatorPos + 1).toList();
  if (argResults.rest.length != expectedRest.length) {
    throwUsageException();
    return;
  }
  for (var i = 0; i < argResults.rest.length; i++) {
    if (expectedRest[i] != argResults.rest[i]) {
      throwUsageException();
    }
  }
}
