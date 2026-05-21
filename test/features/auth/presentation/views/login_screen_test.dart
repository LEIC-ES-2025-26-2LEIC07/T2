import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:clinic_go/core/routing/app_router.dart';
import 'package:clinic_go/features/auth/domain/auth_service.dart';
import 'package:clinic_go/features/auth/presentation/views/login_screen.dart';
import '../../../../helpers/mocks.dart';

Future<void> _setupDI({AuthService? authService}) async {
  await GetIt.I.reset();
  SharedPreferences.setMockInitialValues({});
  GetIt.I.registerSingleton<AuthService>(authService ?? AlwaysSuccessAuth());
}

Widget _buildApp() {
  return MaterialApp(
    onGenerateRoute: (settings) {
      if (settings.name == AppRouter.home) {
        return MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('Home')),
        );
      }
      if (settings.name == AppRouter.register) {
        return MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('Register')),
        );
      }
      return null;
    },
    home: const LoginScreen(),
  );
}

void main() {
  tearDown(() async => GetIt.I.reset());

  group('LoginScreen', () {
    testWidgets('renders email and password fields', (tester) async {
      await _setupDI();
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextField, 'Email'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Password'), findsOneWidget);
    });

    testWidgets('renders title and sign in button', (tester) async {
      await _setupDI();
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.text('Sign in'), findsOneWidget);
    });

    testWidgets('renders forgot password and create account links', (
      tester,
    ) async {
      await _setupDI();
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Forgot password?'), findsOneWidget);
      expect(find.textContaining("Don't have an account"), findsOneWidget);
      expect(find.text('Create one'), findsOneWidget);
    });

    testWidgets('shows error when sign in tapped with empty fields', (
      tester,
    ) async {
      await _setupDI();
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sign in'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Please fill in'), findsOneWidget);
    });

    testWidgets('shows error for invalid email format', (tester) async {
      await _setupDI();
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'Email'),
        'notanemail',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Password'),
        'secret',
      );
      await tester.tap(find.text('Sign in'));
      await tester.pumpAndSettle();

      expect(find.textContaining('valid email'), findsOneWidget);
    });

    testWidgets('shows error on failed sign in', (tester) async {
      await _setupDI(
        authService: AlwaysFailAuth(error: Exception('bad creds')),
      );
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'Email'),
        'user@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Password'),
        'wrong',
      );
      await tester.tap(find.text('Sign in'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Could not sign in'), findsOneWidget);
    });

    testWidgets('navigates to home after successful sign in', (tester) async {
      await _setupDI(authService: AlwaysSuccessAuth());
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'Email'),
        'user@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Password'),
        'password',
      );
      await tester.tap(find.text('Sign in'));
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('Forgot password with blank email shows error message', (
      tester,
    ) async {
      await _setupDI();
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Forgot password?'));
      await tester.pumpAndSettle();

      expect(find.textContaining('email to recover'), findsOneWidget);
    });

    testWidgets('Forgot password with valid email clears error', (
      tester,
    ) async {
      await _setupDI();
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'Email'),
        'user@example.com',
      );
      await tester.tap(find.text('Forgot password?'));
      await tester.pumpAndSettle();

      expect(find.textContaining('email to recover'), findsNothing);
      expect(find.textContaining('Could not send'), findsNothing);
    });

    testWidgets('Create one button navigates to register screen', (
      tester,
    ) async {
      await _setupDI();
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Create one'));
      await tester.pumpAndSettle();

      expect(find.text('Register'), findsOneWidget);
    });
  });
}
