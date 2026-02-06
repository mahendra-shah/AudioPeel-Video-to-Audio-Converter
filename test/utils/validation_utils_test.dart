import 'package:flutter_test/flutter_test.dart';
import 'package:mp3_extract/utils/validation_utils.dart';

void main() {
  group('ValidationUtils.validateFileName', () {
    test('returns null for valid names', () {
      expect(ValidationUtils.validateFileName('my_audio'), isNull);
      expect(ValidationUtils.validateFileName('file-123'), isNull);
      expect(ValidationUtils.validateFileName('a'), isNull);
    });

    test('rejects null', () {
      expect(ValidationUtils.validateFileName(null), isNotNull);
    });

    test('rejects empty string', () {
      expect(ValidationUtils.validateFileName(''), isNotNull);
      expect(ValidationUtils.validateFileName('   '), isNotNull);
    });

    test('rejects names longer than 50 characters', () {
      final longName = 'a' * 51;
      expect(ValidationUtils.validateFileName(longName), isNotNull);
    });

    test('accepts exactly 50 characters', () {
      final name50 = 'a' * 50;
      expect(ValidationUtils.validateFileName(name50), isNull);
    });

    test('rejects names with invalid characters', () {
      expect(ValidationUtils.validateFileName('file<name'), isNotNull);
      expect(ValidationUtils.validateFileName('file>name'), isNotNull);
      expect(ValidationUtils.validateFileName('file:name'), isNotNull);
      expect(ValidationUtils.validateFileName('file"name'), isNotNull);
      expect(ValidationUtils.validateFileName(r'file\name'), isNotNull);
      expect(ValidationUtils.validateFileName('file|name'), isNotNull);
      expect(ValidationUtils.validateFileName('file?name'), isNotNull);
      expect(ValidationUtils.validateFileName('file*name'), isNotNull);
    });

    test('error messages are user-friendly', () {
      expect(ValidationUtils.validateFileName(''), contains('cannot be empty'));
      expect(
        ValidationUtils.validateFileName('a' * 51),
        contains('50 characters'),
      );
      expect(
        ValidationUtils.validateFileName('a<b'),
        contains('invalid characters'),
      );
    });
  });
}
