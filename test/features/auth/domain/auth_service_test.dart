import 'package:clinic_go/features/auth/domain/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthServiceException', () {
    test('toString includes type and message for validation', () {
      const exception = AuthServiceException(
        AuthFailureType.validation,
        'Invalid email.',
      );
      expect(
        exception.toString(),
        'AuthServiceException(AuthFailureType.validation, Invalid email.)',
      );
    });

    test('toString includes type and message for network', () {
      const exception = AuthServiceException(
        AuthFailureType.network,
        'Connection failed.',
      );
      expect(exception.toString(), contains('network'));
      expect(exception.toString(), contains('Connection failed.'));
    });

    test('toString includes type and message for unknown', () {
      const exception = AuthServiceException(
        AuthFailureType.unknown,
        'Unexpected error.',
      );
      expect(exception.toString(), contains('unknown'));
      expect(exception.toString(), contains('Unexpected error.'));
    });

    test('type and message are accessible as fields', () {
      const exception = AuthServiceException(
        AuthFailureType.validation,
        'Bad input.',
      );
      expect(exception.type, AuthFailureType.validation);
      expect(exception.message, 'Bad input.');
    });
  });
}
