// @dart=2.7
// ^ Do not remove until migrated to null safety. More info at https://wiki.atl.workiva.net/pages/viewpage.action?pageId=189370832
import 'dart:html';

import 'package:sse/client/sse_client.dart';

void main() {
  var channel = SseClient(r'/$sseHandler');

  document.querySelector('button').onClick.listen((_) {
    channel.sink.close();
  });

  channel.stream.listen((s) {
    channel.sink.add(s);
  });
}
