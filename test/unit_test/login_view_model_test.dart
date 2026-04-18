import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:clinic_go/features/auth/domain/auth_service.dart';
import 'package:clinic_go/features/auth/presentation/view_models/login_view_model.dart';

// ---------------------------------------------------------------------------
// Hand-rolled mocks — no extra packages required.
// ---------------------------------------------------------------------------

class _AlwaysSuccessAuth implements AuthService {
  @override
  String? get currentUserEmail => null;

  @override
  bool get isLoggedIn => false;

  @override
  Future<void> signIn({required String email, required String password}) async {
    // Success — does nothing.
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<void> resetPassword(String email) async {}
}

class _AlwaysFailAuth implements AuthService {
  final Object error;
  _AlwaysFailAuth({required this.error});

  @override
  String? get currentUserEmail => null;

  @override
  bool get isLoggedIn => false;

  @override
  Future<void> signIn({required String email, required String password}) async {
    throw error;
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<void> resetPassword(String email) async {}
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('LoginViewModel', () {
    // ── Input validation ────────────────────────────────────────────────────

    test('sets errorMessage when email is blank', () async {
      final vm = LoginViewModel(authService: _AlwaysSuccessAuth());

      await vm.signIn(email: '', password: 'secret');

      expect(vm.errorMessage, isNotNull);
      expect(vm.clearPassword, isFalse);
    });

    test('sets errorMessage when password is blank', () async {
      final vm = LoginViewModel(authService: _AlwaysSuccessAuth());

      await vm.signIn(email: 'user@example.com', password: '');

      expect(vm.errorMessage, isNotNull);
      expect(vm.clearPassword, isFalse);
    });

    test('sets errorMessage when email has no @', () async {
      final vm = LoginViewModel(authService: _AlwaysSuccessAuth());

      await vm.signIn(email: 'notanemail', password: 'secret');

      expect(vm.errorMessage, isNotNull);
      expect(vm.clearPassword, isFalse);
    });

    // ── AuthException path ──────────────────────────────────────────────────

    test(
      'sets errorMessage to "Credenciais inválidas" when AuthException is thrown',
      () async {
        final vm = LoginViewModel(
          authService: _AlwaysFailAuth(
            error: const AuthException('Invalid login credentials'),
          ),
        );

        await vm.signIn(email: 'user@example.com', password: 'wrong');

        expect(vm.errorMessage, 'Credenciais inválidas');
      },
    );

    test('sets clearPassword=true on AuthException', () async {
      final vm = LoginViewModel(
        authService: _AlwaysFailAuth(
          error: const AuthException('Invalid login credentials'),
        ),
      );

      await vm.signIn(email: 'user@example.com', password: 'wrong');

      expect(vm.clearPassword, isTrue);
    });

    test(
      'clearPassword resets to false after acknowledgePasswordClear',
      () async {
        final vm = LoginViewModel(
          authService: _AlwaysFailAuth(
            error: const AuthException('Invalid login credentials'),
          ),
        );

        await vm.signIn(email: 'user@example.com', password: 'wrong');
        expect(vm.clearPassword, isTrue);

        vm.acknowledgePasswordClear();

        expect(vm.clearPassword, isFalse);
      },
    );

    // ── Generic error path ──────────────────────────────────────────────────

    test('sets clearPassword=true on generic error', () async {
      final vm = LoginViewModel(
        authService: _AlwaysFailAuth(error: Exception('network error')),
      );

      await vm.signIn(email: 'user@example.com', password: 'secret');

      expect(vm.errorMessage, isNotNull);
      expect(vm.clearPassword, isTrue);
    });

    // ── Success path ────────────────────────────────────────────────────────

    test(
      'clears errorMessage and keeps clearPassword=false on success',
      () async {
        final vm = LoginViewModel(authService: _AlwaysSuccessAuth());

        await vm.signIn(email: 'user@example.com', password: 'correct');

        expect(vm.errorMessage, isNull);
        expect(vm.clearPassword, isFalse);
      },
    );

    test('isLoading is false after signIn completes', () async {
      final vm = LoginViewModel(authService: _AlwaysSuccessAuth());

      await vm.signIn(email: 'user@example.com', password: 'correct');

      expect(vm.isLoading, isFalse);
    });

    // ── resetPassword ───────────────────────────────────────────────────────

    test('sets errorMessage when resetPassword email is blank', () async {
      final vm = LoginViewModel(authService: _AlwaysSuccessAuth());

      await vm.resetPassword('');

      expect(vm.errorMessage, isNotNull);
    });

    test('clears errorMessage on successful resetPassword', () async {
      final vm = LoginViewModel(authService: _AlwaysSuccessAuth());

      await vm.resetPassword('user@example.com');

      expect(vm.errorMessage, isNull);
    });
  });
}
