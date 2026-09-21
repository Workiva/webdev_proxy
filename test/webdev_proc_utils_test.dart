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

@TestOn('vm')
import 'package:test/test.dart';

import 'package:webdev_proxy/src/webdev_proc_utils.dart';

import 'util.dart';

void main() {
  group('getGlobalWebdevVersion()', () {
    setUp(() {
      cachedWebdevVersionResult = null;
    });

    tearDown(() {
      cachedWebdevVersionResult = null;
    });

    test('with webdev not activated', () async {
      await deactivateWebdev();
      expect(getGlobalWebdevVersion(), isNull);
    });

    test('with webdev activated', () async {
      await activateWebdev(webdevCompatibility.toString());
      final version = getGlobalWebdevVersion();
      expect(version, isNotNull);
      expect(webdevCompatibility.allows(version!), isTrue);
    });
  });

  test('printWebdevServeHelp', () async {
    await activateWebdev(webdevCompatibility.toString());
    expect(printWebdevServeHelp(), completion(0));
  });
}
