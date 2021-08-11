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

    test('nested directory', () {
      expect(parseDirectoryArgs(['web/nested/dir/:9000']),
          {'web/nested/dir/': 9000});
    });
  });

  group('parseHostname', () {
    test('with no args', () {
      final result = parseHostname([]);
      expect(result.hostname, 'localhost');
      expect(result.remainingArgs, []);
    });

    test('with no hostname arg', () {
      final result = parseHostname(['--release']);
      expect(result.hostname, 'localhost');
      expect(result.remainingArgs, ['--release']);
    });

    test('--hostname=<value>', () {
      final result = parseHostname(['--hostname=0.0.0.0']);
      expect(result.hostname, '0.0.0.0');
      expect(result.remainingArgs, []);
    });

    test('--hostname=<value> with trailing args', () {
      final result = parseHostname(['--hostname=0.0.0.0', '--release']);
      expect(result.hostname, '0.0.0.0');
      expect(result.remainingArgs, ['--release']);
    });

    test('--hostname value', () {
      final result = parseHostname(['--hostname', '0.0.0.0']);
      expect(result.hostname, '0.0.0.0');
      expect(result.remainingArgs, []);
    });

    test('--hostname value with trailing args', () {
      final result = parseHostname(['--hostname', '0.0.0.0', '--release']);
      expect(result.hostname, '0.0.0.0');
      expect(result.remainingArgs, ['--release']);
    });

  });
}
