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

import 'package:glob/glob.dart';
import 'package:shelf/shelf.dart' as shelf;

shelf.Middleware rewriteMiddleware(Map<Glob, String> rules) {
  return (shelf.Handler innerHandler) {
    return (shelf.Request req) {
      for (final glob in rules.keys) {
        if (glob.matches(req.requestedUri.path)) {
          return innerHandler(req.change(path: rules[glob]));
        }
      }
      return innerHandler(req);
    };
  };
}
