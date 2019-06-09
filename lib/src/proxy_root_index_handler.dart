// Copyright 2019 Workiva Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf_proxy/shelf_proxy.dart' as shelf_proxy;

/// Returns a handler that always fetches the root index path via the given
/// [proxyHandler], which is expected to be a handler returned from the
/// `shelf_proxy` package's [shelf_proxy.proxyHandler] function.
///
/// Each request given to the returned handler will be used to create a copy
/// that is identical except that its URI's path is `/`.
shelf.Handler proxyRootIndexHandler(shelf.Handler proxyHandler) {
  return (shelf.Request req) {
    final indexRequest = shelf.Request(
        'GET', req.requestedUri.replace(path: '/'),
        context: req.context,
        encoding: req.encoding,
        headers: req.headers,
        protocolVersion: req.protocolVersion);
    return proxyHandler(indexRequest);
  };
}
