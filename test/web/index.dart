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
