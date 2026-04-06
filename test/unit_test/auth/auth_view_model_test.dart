import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:clinic_go/data/repositories/auth_repository.dart';
import 'package:clinic_go/domain/models/user_model.dart';
import 'package:clinic_go/ui/auth/view_models/auth_view_model.dart';

import 'auth_view_model_test.mocks.dart';

// ─── Fake UserModel ──────────────────────────────────────────────────────────

const _fakeUser = UserModel(
  id: 'uuid-123',
  email: 'test@example.com',
  fullName: 'Test User',
);

// ─── Generate mocks ───────────────────────────────────────────────────────────
@GenerateMocks([AuthRepository])
void main() {
  late MockAuthRepository mockRepo;
  late StreamController<UserModel?> authStateController;

  setUp(() {
    mockRepo = MockAuthRepository();
    authStateController = StreamController<UserModel?>.broadcast();

    // Default stubs used by most tests.
    when(mockRepo.currentUser).thenReturn(null);
    when(
      mockRepo.authStateChanges,
    ).thenAnswer((_) => authStateController.stream);
  });

  tearDown(() {
    authStateController.close();
  });

  AuthViewModel buildVm() => AuthViewModel(repo: mockRepo);

  // ─── Initial state ─────────────────────────────────────────────────────────

  group('_init – unauthenticated', () {
    test('status is unauthenticated when no current user', () {
      final vm = buildVm();
      expect(vm.status, AuthStatus.unauthenticated);
      expect(vm.user, isNull);
    });

    test('isAuthenticated is false when unauthenticated', () {
      expect(buildVm().isAuthenticated, isFalse);
    });
  });

  group('_init – already authenticated', () {
    setUp(() {
      when(mockRepo.currentUser).thenReturn(_fakeUser);
      when(mockRepo.fetchCurrentUser(any)).thenAnswer((_) async => _fakeUser);
    });

    test('status is authenticated and user is populated', () {
      final vm = buildVm();
      expect(vm.status, AuthStatus.authenticated);
      expect(vm.user, _fakeUser);
    });

    test('isAuthenticated is true', () {
      expect(buildVm().isAuthenticated, isTrue);
    });

    test('notifies after fetchCurrentUser completes', () async {
      final vm = buildVm();
      var notified = false;
      vm.addListener(() => notified = true);
      await Future.delayed(Duration.zero); // let the async hydration finish
      expect(notified, isTrue);
    });
  });

  // ─── authStateChanges stream ───────────────────────────────────────────────

  group('authStateChanges stream', () {
    test('transitions to authenticated when stream emits a user', () async {
      final vm = buildVm();
      when(mockRepo.fetchCurrentUser(any)).thenAnswer((_) async => _fakeUser);

      authStateController.add(_fakeUser);
      await Future.delayed(Duration.zero);

      expect(vm.status, AuthStatus.authenticated);
      expect(vm.user, _fakeUser);
    });

    test('transitions to unauthenticated when stream emits null', () async {
      final vm = buildVm();
      authStateController.add(null);
      await Future.delayed(Duration.zero);

      expect(vm.status, AuthStatus.unauthenticated);
      expect(vm.user, isNull);
    });
  });

  // ─── signIn ────────────────────────────────────────────────────────────────

  group('signIn', () {
    test('sets status to authenticated on success', () async {
      when(
        mockRepo.signIn(
          email: anyNamed('email'),
          password: anyNamed('password'),
        ),
      ).thenAnswer((_) async => _fakeUser);

      final vm = buildVm();
      await vm.signIn(email: 'test@example.com', password: 'pass123');

      expect(vm.status, AuthStatus.authenticated);
      expect(vm.user, _fakeUser);
      expect(vm.errorMessage, isNull);
    });

    test('sets status to loading while waiting', () async {
      final completer = Completer<UserModel>();
      when(
        mockRepo.signIn(
          email: anyNamed('email'),
          password: anyNamed('password'),
        ),
      ).thenAnswer((_) => completer.future);

      final vm = buildVm();
      final future = vm.signIn(email: 'test@example.com', password: 'pass');

      expect(vm.status, AuthStatus.loading);
      completer.complete(_fakeUser);
      await future;
    });

    test('sets status to error on AuthException', () async {
      when(
        mockRepo.signIn(
          email: anyNamed('email'),
          password: anyNamed('password'),
        ),
      ).thenThrow(const AuthException('Invalid credentials'));

      final vm = buildVm();
      await vm.signIn(email: 'bad@example.com', password: 'wrong');

      expect(vm.status, AuthStatus.error);
      expect(vm.errorMessage, 'Invalid credentials');
    });

    test('isAuthenticated returns false on error', () async {
      when(
        mockRepo.signIn(
          email: anyNamed('email'),
          password: anyNamed('password'),
        ),
      ).thenThrow(const AuthException('oops'));

      final vm = buildVm();
      await vm.signIn(email: 'x@x.com', password: 'y');
      expect(vm.isAuthenticated, isFalse);
    });
  });

  // ─── signUp ────────────────────────────────────────────────────────────────

  group('signUp', () {
    test('sets status to authenticated on success', () async {
      when(
        mockRepo.signUp(
          email: anyNamed('email'),
          password: anyNamed('password'),
          fullName: anyNamed('fullName'),
          phone: anyNamed('phone'),
        ),
      ).thenAnswer((_) async => _fakeUser);

      final vm = buildVm();
      await vm.signUp(
        email: 'new@example.com',
        password: 'pass123',
        fullName: 'New User',
      );

      expect(vm.status, AuthStatus.authenticated);
      expect(vm.user, _fakeUser);
    });

    test('sets error status on AuthException', () async {
      when(
        mockRepo.signUp(
          email: anyNamed('email'),
          password: anyNamed('password'),
          fullName: anyNamed('fullName'),
          phone: anyNamed('phone'),
        ),
      ).thenThrow(const AuthException('Email already registered'));

      final vm = buildVm();
      await vm.signUp(email: 'dup@example.com', password: 'pass123');

      expect(vm.status, AuthStatus.error);
      expect(vm.errorMessage, 'Email already registered');
    });

    test('passes optional parameters correctly', () async {
      when(
        mockRepo.signUp(
          email: anyNamed('email'),
          password: anyNamed('password'),
          fullName: anyNamed('fullName'),
          phone: anyNamed('phone'),
        ),
      ).thenAnswer((_) async => _fakeUser);

      final vm = buildVm();
      await vm.signUp(
        email: 'a@b.com',
        password: 'abc123',
        fullName: 'Ana',
        phone: '912345678',
      );

      verify(
        mockRepo.signUp(
          email: 'a@b.com',
          password: 'abc123',
          fullName: 'Ana',
          phone: '912345678',
        ),
      ).called(1);
    });
  });

  // ─── signOut ───────────────────────────────────────────────────────────────

  group('signOut', () {
    test('sets status to unauthenticated on success', () async {
      when(mockRepo.signOut()).thenAnswer((_) async {});

      // Start from authenticated state
      when(mockRepo.currentUser).thenReturn(_fakeUser);
      when(mockRepo.fetchCurrentUser(any)).thenAnswer((_) async => _fakeUser);
      final vm = buildVm();

      await vm.signOut();

      expect(vm.status, AuthStatus.unauthenticated);
      expect(vm.user, isNull);
    });

    test('sets error status on failure', () async {
      when(
        mockRepo.signOut(),
      ).thenThrow(const AuthException('Failed to sign out. Please try again.'));

      final vm = buildVm();
      await vm.signOut();

      expect(vm.status, AuthStatus.error);
      expect(vm.errorMessage, 'Failed to sign out. Please try again.');
    });
  });

  // ─── clearError ───────────────────────────────────────────────────────────

  group('clearError', () {
    test('resets error message and status to unauthenticated', () async {
      when(
        mockRepo.signIn(
          email: anyNamed('email'),
          password: anyNamed('password'),
        ),
      ).thenThrow(const AuthException('oops'));

      final vm = buildVm();
      await vm.signIn(email: 'x@x.com', password: 'y');
      expect(vm.status, AuthStatus.error);

      vm.clearError();

      expect(vm.status, AuthStatus.unauthenticated);
      expect(vm.errorMessage, isNull);
    });

    test('does not change status when not in error state', () {
      final vm = buildVm();
      expect(vm.status, AuthStatus.unauthenticated);

      vm.clearError();

      // status should still be unauthenticated (no error to clear)
      expect(vm.status, AuthStatus.unauthenticated);
    });

    test('notifies listeners after clearError', () async {
      when(
        mockRepo.signIn(
          email: anyNamed('email'),
          password: anyNamed('password'),
        ),
      ).thenThrow(const AuthException('err'));

      final vm = buildVm();
      await vm.signIn(email: 'x@x.com', password: 'y');

      var notified = false;
      vm.addListener(() => notified = true);
      vm.clearError();
      expect(notified, isTrue);
    });
  });

  // ─── Notification behaviour ────────────────────────────────────────────────

  group('notifyListeners', () {
    test('notifies after successful signIn', () async {
      when(
        mockRepo.signIn(
          email: anyNamed('email'),
          password: anyNamed('password'),
        ),
      ).thenAnswer((_) async => _fakeUser);

      final vm = buildVm();
      var callCount = 0;
      vm.addListener(() => callCount++);

      await vm.signIn(email: 'a@b.com', password: 'pass');

      // loading + authenticated = 2 notifications minimum
      expect(callCount, greaterThanOrEqualTo(2));
    });
  });
}
