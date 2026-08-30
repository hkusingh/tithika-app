import 'package:flutter_test/flutter_test.dart';
import 'package:tithika/services/update_service.dart';

void main() {
  group('UpdateService.isNewer', () {
    test('detects a newer patch, minor, and major version', () {
      expect(UpdateService.isNewer('1.7.4', '1.7.3'), isTrue);
      expect(UpdateService.isNewer('1.8.0', '1.7.3'), isTrue);
      expect(UpdateService.isNewer('2.0.0', '1.7.3'), isTrue);
    });

    test('identical versions are not newer', () {
      expect(UpdateService.isNewer('1.7.3', '1.7.3'), isFalse);
    });

    test('older versions are not newer', () {
      expect(UpdateService.isNewer('1.7.2', '1.7.3'), isFalse);
      expect(UpdateService.isNewer('1.6.9', '1.7.0'), isFalse);
      expect(UpdateService.isNewer('0.9.9', '1.0.0'), isFalse);
    });

    test(
      'compares segments numerically, not lexically — 1.10.0 beats 1.9.0',
      () {
        // A plain string compare would rank "1.9.0" above "1.10.0" because
        // '9' > '1', which would silently stop prompting after x.9.
        expect(UpdateService.isNewer('1.10.0', '1.9.0'), isTrue);
        expect(UpdateService.isNewer('1.9.0', '1.10.0'), isFalse);
        expect(UpdateService.isNewer('1.7.10', '1.7.9'), isTrue);
      },
    );

    test('handles differing segment counts', () {
      expect(UpdateService.isNewer('1.8', '1.7.9'), isTrue);
      expect(UpdateService.isNewer('1.7.0.1', '1.7.0'), isTrue);
      expect(UpdateService.isNewer('1.7', '1.7.0'), isFalse);
    });

    test('non-numeric segments degrade to 0 rather than throwing', () {
      expect(UpdateService.isNewer('1.7.3-rc1', '1.7.3'), isFalse);
      expect(UpdateService.isNewer('1.8.0-beta', '1.7.3'), isTrue);
      expect(() => UpdateService.isNewer('abc', '1.0.0'), returnsNormally);
    });
  });
}
