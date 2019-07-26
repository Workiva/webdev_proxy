import 'package:shelf/shelf.dart';

Iterable<Handler> get handlers => [
      customStatusHandler,
    ];

Response customStatusHandler(Request request) {
  final customStatus = request.requestedUri.queryParameters['status'];
  if (customStatus != null) {
    return Response(int.parse(customStatus));
  }
  return Response.notFound('');
}
