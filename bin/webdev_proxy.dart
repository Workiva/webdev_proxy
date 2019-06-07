import 'dart:io';

import 'package:webdev_proxy/src/executable.dart' as executable;

void main(List<String> args) async {
  exitCode = await executable.run(args);
}
