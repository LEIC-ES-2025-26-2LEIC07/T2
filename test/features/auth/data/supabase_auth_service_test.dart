import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:clinic_go/features/auth/data/supabase_auth_service.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockUser extends Mock implements User {}

void main() {
  late MockSupabaseClient mockClient;
  late MockGoTrueClient mockAuth;
  late MockUser mockUser;
  late SupabaseAuthService service;

  setUp(() {
    mockClient = MockSupabaseClient();
    mockAuth = MockGoTrueClient();
    mockUser = MockUser();

    when(() => mockClient.auth).thenReturn(mockAuth);
    when(() => mockUser.email).thenReturn('user@example.com');

    service = SupabaseAuthService(client: mockClient);
  });

  group('SupabaseAuthService', () {
    group('currentUserEmail', () {
      test('currentUserEmail: user logged in → returns email', () {
        when(() => mockAuth.currentUser).thenReturn(mockUser);
        expect(service.currentUserEmail, 'user@example.com');
      });

      test('currentUserEmail: no user → returns null', () {
        when(() => mockAuth.currentUser).thenReturn(null);
        expect(service.currentUserEmail, isNull);
      });
    });

    group('isLoggedIn', () {
      test('isLoggedIn: user exists → returns true', () {
        when(() => mockAuth.currentUser).thenReturn(mockUser);
        expect(service.isLoggedIn, isTrue);
      });

      test('isLoggedIn: no user → returns false', () {
        when(() => mockAuth.currentUser).thenReturn(null);
        expect(service.isLoggedIn, isFalse);
      });
    });

    group('authStateChanges', () {
      test('authStateChanges: signedIn event → emits true', () async {
        final controller = StreamController<AuthState>();
        when(
          () => mockAuth.onAuthStateChange,
        ).thenAnswer((_) => controller.stream);

        final values = <bool>[];
        final subscription = service.authStateChanges.listen(values.add);

        controller.add(const AuthState(AuthChangeEvent.signedIn, null));
        await Future<void>.delayed(Duration.zero);

        expect(values, [true]);
        await subscription.cancel();
        await controller.close();
      });

      test('authStateChanges: signedOut event → emits false', () async {
        final controller = StreamController<AuthState>();
        when(
          () => mockAuth.onAuthStateChange,
        ).thenAnswer((_) => controller.stream);

        final values = <bool>[];
        final subscription = service.authStateChanges.listen(values.add);

        controller.add(const AuthState(AuthChangeEvent.signedOut, null));
        await Future<void>.delayed(Duration.zero);

        expect(values, [false]);
        await subscription.cancel();
        await controller.close();
      });
    });

    group('signIn', () {
      test('signIn: happy path → completes without error', () async {
        when(
          () => mockAuth.signInWithPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async => AuthResponse());

        await expectLater(
          service.signIn(email: 'user@example.com', password: 'pass'),
          completes,
        );
      });

      test('signIn: AuthException thrown → propagates', () {
        when(
          () => mockAuth.signInWithPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenThrow(const AuthException('Invalid credentials'));

        expect(
          () => service.signIn(email: 'user@example.com', password: 'wrong'),
          throwsA(isA<AuthException>()),
        );
      });
    });

    group('signUp', () {
      test('signUp: happy path → completes without error', () async {
        when(
          () => mockAuth.signUp(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async => AuthResponse());

        await expectLater(
          service.signUp(email: 'new@example.com', password: 'pass'),
          completes,
        );
      });

      test('signUp: AuthException thrown → propagates', () {
        when(
          () => mockAuth.signUp(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenThrow(const AuthException('Email already in use'));

        expect(
          () => service.signUp(email: 'existing@example.com', password: 'pass'),
          throwsA(isA<AuthException>()),
        );
      });
    });

    group('signOut', () {
      test('signOut: happy path → completes without error', () async {
        when(() => mockAuth.signOut()).thenAnswer((_) async {});

        await expectLater(service.signOut(), completes);
      });

      test('signOut: AuthException thrown → propagates', () {
        when(
          () => mockAuth.signOut(),
        ).thenThrow(const AuthException('Not signed in'));

        expect(() => service.signOut(), throwsA(isA<AuthException>()));
      });
    });

    group('resetPassword', () {
      test('resetPassword: happy path → completes without error', () async {
        when(
          () => mockAuth.resetPasswordForEmail(any()),
        ).thenAnswer((_) async {});

        await expectLater(service.resetPassword('user@example.com'), completes);
      });

      test('resetPassword: AuthException thrown → propagates', () {
        when(
          () => mockAuth.resetPasswordForEmail(any()),
        ).thenThrow(const AuthException('Email not found'));

        expect(
          () => service.resetPassword('unknown@example.com'),
          throwsA(isA<AuthException>()),
        );
      });
    });
  });
}
