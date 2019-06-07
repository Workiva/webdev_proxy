@TestOn('vm')
import 'package:pub_semver/pub_semver.dart';
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

    test('with webdev not activated', () {
      deactivateWebdev();
      expect(getGlobalWebdevVersion(), isNull);
    });

    test('with webdev activated', () {
      activateWebdev('2.0.0');
      expect(getGlobalWebdevVersion(), Version.parse('2.0.0'));
    });
  });

  test('printWebdevServeHelp', () {
    activateWebdev('2.0.0');
    expect(printWebdevServeHelp(), completion(0));
  }, timeout: Timeout(Duration(seconds: 20)));
}
