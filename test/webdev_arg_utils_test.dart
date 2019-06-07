@TestOn('vm')
import 'package:test/test.dart';

import 'package:webdev_proxy/src/webdev_arg_utils.dart';

void main() {
  group('parseDirectoryArgs()', () {
    test('defaults to web:8080', () {
      expect(parseDirectoryArgs([]), {'web': 8080});
    });

    test('no matching args', () {
      expect(parseDirectoryArgs(['--foo=bar', '-v', '--flag']), {'web': 8080});
    });

    test('one mapping', () {
      expect(parseDirectoryArgs(['web:8080']), {'web': 8080});
    });

    test('multiple distinct mappings', () {
      expect(parseDirectoryArgs(['web:8080', 'test:8081']),
          {'web': 8080, 'test': 8081});
    });

    test('last one wins when dir has multiple ports', () {
      expect(parseDirectoryArgs(['web:8080', 'web:8081']), {'web': 8081});
    });

    test('ports omitted', () {
      expect(parseDirectoryArgs(['web', 'test']), {'web': 8080, 'test': 8081});
    });
  });
}
