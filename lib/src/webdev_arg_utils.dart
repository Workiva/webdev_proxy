final _defaultWebDirs = const ['web'];
final _dirPattern = RegExp(r'^(\w+)(?::(\d+))?$');

Map<String, int> parseDirectoryArgs(List<String> args) {
  final result = <String, int>{};
  var basePort = 8080;
  final dirArgs = args.where((_dirPattern.hasMatch));
  if (dirArgs.isEmpty) {
    for (final dir in _defaultWebDirs) {
      result[dir] = basePort++;
    }
  } else {
    for (final arg in dirArgs) {
      final splitOption = arg.split(':');
      if (splitOption.length == 2) {
        result[splitOption.first] = int.parse(splitOption.last);
      } else {
        result[arg] = basePort++;
      }
    }
  }
  return result;
}

String parseHostname(List<String> args) {
  for (var i = 0; i < args.length; i++) {
    if (!args[i].startsWith('--hostname')) {
      continue;
    }
    if (args[i].contains('=')) {
      // --hostname=<value>
      return args[i].split('=')[1];
    }
    if (i + 1 < args.length && !args[i + 1].startsWith('-')) {
      // --hostname <value>
      return args[i + 1];
    }
  }
  return 'localhost';

  // TODO: Use when webdev `--hostname=any` support is released
  // HttpMultiServer supports `any` as a more flexible localhost.
  // return 'any';
}
