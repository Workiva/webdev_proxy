import 'dart:io';

import 'package:path/path.dart' as p;

const cacheDirPath = '.dart_tool/webdev_proxy';

void createCacheDir({String subPath}) {
  var path = cacheDirPath;
  if (subPath != null) {
    path = p.join(path, subPath);
  }
  final dir = Directory(path);
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }
}
