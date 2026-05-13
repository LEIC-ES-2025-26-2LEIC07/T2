import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:clinic_go/features/auth/data/supabase_auth_service.dart';
import 'package:clinic_go/features/auth/domain/auth_service.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockUser extends Mock implements User {}

class MockSession extends Mock implements Session {}

void main() {
  late MockSupabaseClient mockClient;
  late MockGoTrueClient mockAuth;
  late MockUser mockUser;
  late MockSession mockSession;
  late SupabaseAuthService service;

  setUpAll(() {
    registerFallbackValue(UserAttributes());
  });

  setUp(() {
    mockClient = MockSupabaseClient();
    mockAuth = MockGoTrueClient();
    mockUser = MockUser();
    mockSession = MockSession();

    when(() => mockClient.auth).thenReturn(mockAuth);
    when(() => mockUser.email).thenReturn('user@example.com');
    when(() => mockUser.userMetadata).thenReturn(const {'name': 'Test'});

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
      test('isLoggedIn: active session → returns true', () {
        when(() => mockAuth.currentSession).thenReturn(mockSession);
        expect(service.isLoggedIn, isTrue);
      });

      test('isLoggedIn: no session → returns false', () {
        when(() => mockAuth.currentSession).thenReturn(null);
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

    group('currentUserMetadata', () {
      test('returns user metadata when user is logged in', () {
        when(() => mockAuth.currentUser).thenReturn(mockUser);
        expect(service.currentUserMetadata, {'name': 'Test'});
      });

      test('returns empty map when no user', () {
        when(() => mockAuth.currentUser).thenReturn(null);
        expect(service.currentUserMetadata, isEmpty);
      });
    });

    group('updateProfile', () {
      test('happy path → completes without error', () async {
        when(() => mockAuth.updateUser(any())).thenAnswer(
          (_) async => UserResponse.fromJson({
            'id': 'test-id',
            'created_at': '2026-01-01T00:00:00.000Z',
            'app_metadata': <String, dynamic>{},
            'aud': 'authenticated',
          }),
        );

        await expectLater(
          service.updateProfile(
            email: 'user@example.com',
            metadata: {'name': 'Test'},
          ),
          completes,
        );
      });

      test(
        'AuthException with 4xx status → throws validation AuthServiceException',
        () async {
          when(() => mockAuth.updateUser(any())).thenThrow(
            const AuthException('Email already taken', statusCode: '422'),
          );

          await expectLater(
            service.updateProfile(email: 'taken@example.com', metadata: {}),
            throwsA(
              isA<AuthServiceException>().having(
                (e) => e.type,
                'type',
                AuthFailureType.validation,
              ),
            ),
          );
        },
      );

      test(
        'AuthException with "network" message → throws network AuthServiceException',
        () async {
          when(
            () => mockAuth.updateUser(any()),
          ).thenThrow(const AuthException('network error occurred'));

          await expectLater(
            service.updateProfile(email: 'user@example.com', metadata: {}),
            throwsA(
              isA<AuthServiceException>().having(
                (e) => e.type,
                'type',
                AuthFailureType.network,
              ),
            ),
          );
        },
      );

      test(
        'AuthException with no keyword match → throws unknown AuthServiceException',
        () async {
          when(() => mockAuth.updateUser(any())).thenThrow(
            const AuthException('Internal server error', statusCode: '500'),
          );

          await expectLater(
            service.updateProfile(email: 'user@example.com', metadata: {}),
            throwsA(
              isA<AuthServiceException>().having(
                (e) => e.type,
                'type',
                AuthFailureType.unknown,
              ),
            ),
          );
        },
      );

      test('TimeoutException → throws network AuthServiceException', () async {
        when(
          () => mockAuth.updateUser(any()),
        ).thenThrow(TimeoutException('Request timed out'));

        await expectLater(
          service.updateProfile(email: 'user@example.com', metadata: {}),
          throwsA(
            isA<AuthServiceException>()
                .having((e) => e.type, 'type', AuthFailureType.network)
                .having((e) => e.message, 'message', 'The request timed out.'),
          ),
        );
      });

      test(
        'generic socket error → throws network AuthServiceException',
        () async {
          when(
            () => mockAuth.updateUser(any()),
          ).thenThrow(Exception('socket connection refused'));

          await expectLater(
            service.updateProfile(email: 'user@example.com', metadata: {}),
            throwsA(
              isA<AuthServiceException>().having(
                (e) => e.type,
                'type',
                AuthFailureType.network,
              ),
            ),
          );
        },
      );

      test(
        'generic unknown error → throws unknown AuthServiceException',
        () async {
          when(
            () => mockAuth.updateUser(any()),
          ).thenThrow(Exception('something unexpected'));

          await expectLater(
            service.updateProfile(email: 'user@example.com', metadata: {}),
            throwsA(
              isA<AuthServiceException>().having(
                (e) => e.type,
                'type',
                AuthFailureType.unknown,
              ),
            ),
          );
        },
      );
    });
  });
}
