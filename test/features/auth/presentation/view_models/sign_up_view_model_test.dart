import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:clinic_go/features/auth/presentation/view_models/sign_up_view_model.dart';
import '../../../../helpers/mocks.dart';

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('SignUpViewModel', () {
    // ── Input validation ────────────────────────────────────────────────────

    test('sets errorMessage when email is blank', () async {
      final vm = SignUpViewModel(authService: AlwaysSuccessAuth());
      await vm.signUp(email: '', password: 'abc123', confirmPassword: 'abc123');
      expect(vm.errorMessage, isNotNull);
      expect(vm.success, isFalse);
    });

    test('sets errorMessage when password is blank', () async {
      final vm = SignUpViewModel(authService: AlwaysSuccessAuth());
      await vm.signUp(email: 'a@b.com', password: '', confirmPassword: '');
      expect(vm.errorMessage, isNotNull);
      expect(vm.success, isFalse);
    });

    test('sets errorMessage when email has no @', () async {
      final vm = SignUpViewModel(authService: AlwaysSuccessAuth());
      await vm.signUp(
        email: 'notanemail',
        password: 'abc123',
        confirmPassword: 'abc123',
      );
      expect(vm.errorMessage, isNotNull);
      expect(vm.success, isFalse);
    });

    test(
      'sets errorMessage when password is shorter than 6 characters',
      () async {
        final vm = SignUpViewModel(authService: AlwaysSuccessAuth());
        await vm.signUp(
          email: 'a@b.com',
          password: 'abc',
          confirmPassword: 'abc',
        );
        expect(vm.errorMessage, isNotNull);
        expect(vm.success, isFalse);
      },
    );

    test('sets errorMessage when passwords do not match', () async {
      final vm = SignUpViewModel(authService: AlwaysSuccessAuth());
      await vm.signUp(
        email: 'a@b.com',
        password: 'abc123',
        confirmPassword: 'xyz999',
      );
      expect(vm.errorMessage, contains('match'));
      expect(vm.success, isFalse);
    });

    // ── AuthException path ──────────────────────────────────────────────────

    test('sets errorMessage to friendly text on AuthException', () async {
      final vm = SignUpViewModel(
        authService: AlwaysFailAuth(
          error: const AuthException('User already registered'),
        ),
      );
      await vm.signUp(
        email: 'a@b.com',
        password: 'abc123',
        confirmPassword: 'abc123',
      );
      expect(vm.errorMessage, contains('registered'));
      expect(vm.success, isFalse);
    });

    test('sets errorMessage on generic Exception', () async {
      final vm = SignUpViewModel(
        authService: AlwaysFailAuth(error: Exception('network error')),
      );
      await vm.signUp(
        email: 'a@b.com',
        password: 'abc123',
        confirmPassword: 'abc123',
      );
      expect(vm.errorMessage, isNotNull);
      expect(vm.success, isFalse);
    });

    // ── Success path ────────────────────────────────────────────────────────

    test(
      'sets success=true and clears errorMessage on valid sign-up',
      () async {
        final vm = SignUpViewModel(authService: AlwaysSuccessAuth());
        await vm.signUp(
          email: 'a@b.com',
          password: 'abc123',
          confirmPassword: 'abc123',
        );
        expect(vm.success, isTrue);
        expect(vm.errorMessage, isNull);
      },
    );

    test('isLoading is false after signUp completes', () async {
      final vm = SignUpViewModel(authService: AlwaysSuccessAuth());
      await vm.signUp(
        email: 'a@b.com',
        password: 'abc123',
        confirmPassword: 'abc123',
      );
      expect(vm.isLoading, isFalse);
    });

    test('clearError removes the displayed error', () async {
      final vm = SignUpViewModel(authService: AlwaysSuccessAuth());
      await vm.signUp(email: '', password: 'abc123', confirmPassword: 'abc123');
      expect(vm.errorMessage, isNotNull);

      vm.clearError();
      expect(vm.errorMessage, isNull);
    });
  });
}
