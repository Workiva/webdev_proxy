import 'package:sse/client/sse_client.dart';

void main() {
  var channel = SseClient(r'/$sseHandler');
  channel.stream.listen((s) {
    channel.sink.add(s);
  });
}
