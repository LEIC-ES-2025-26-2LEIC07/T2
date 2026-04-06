import 'package:flutter_test/flutter_test.dart';
import 'package:clinic_go/data/repositories/auth_repository.dart';

void main() {
  // ─── AuthException ─────────────────────────────────────────────────────────

  group('AuthException', () {
    test('stores message correctly', () {
      const e = AuthException('Something went wrong');
      expect(e.message, 'Something went wrong');
    });

    test('toString includes the message', () {
      const e = AuthException('Oops');
      expect(e.toString(), 'AuthException: Oops');
    });

    test('can be used as a thrown exception', () {
      expect(
        () => throw const AuthException('test'),
        throwsA(
          isA<AuthException>().having((e) => e.message, 'message', 'test'),
        ),
      );
    });
  });
}
