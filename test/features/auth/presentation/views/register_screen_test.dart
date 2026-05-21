import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:clinic_go/core/routing/app_router.dart';
import 'package:clinic_go/features/auth/domain/auth_service.dart';
import 'package:clinic_go/features/auth/presentation/views/register_screen.dart';
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
      return null;
    },
    home: const RegisterScreen(),
  );
}

void main() {
  tearDown(() async => GetIt.I.reset());

  group('RegisterScreen', () {
    testWidgets('renders three text fields', (tester) async {
      await _setupDI();
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsNWidgets(3));
    });

    testWidgets('renders title and create account button', (tester) async {
      await _setupDI();
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Create account'), findsWidgets);
      expect(find.text('Sign up to start using ClinicGO.'), findsOneWidget);
    });

    testWidgets('renders already have an account link', (tester) async {
      await _setupDI();
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      expect(find.textContaining('Already have an account'), findsOneWidget);
      expect(find.text('Sign in'), findsOneWidget);
    });

    testWidgets('shows error when form is submitted empty', (tester) async {
      await _setupDI();
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Create account').last);
      await tester.pumpAndSettle();

      expect(find.textContaining('Please fill in'), findsOneWidget);
    });

    testWidgets('shows error for invalid email', (tester) async {
      await _setupDI();
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'notanemail');
      await tester.enterText(fields.at(1), 'pass123');
      await tester.enterText(fields.at(2), 'pass123');

      await tester.tap(find.text('Create account').last);
      await tester.pumpAndSettle();

      expect(find.textContaining('valid email'), findsOneWidget);
    });

    testWidgets('shows error when passwords do not match', (tester) async {
      await _setupDI();
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'user@example.com');
      await tester.enterText(fields.at(1), 'password123');
      await tester.enterText(fields.at(2), 'different');

      await tester.tap(find.text('Create account').last);
      await tester.pumpAndSettle();

      expect(find.textContaining('match'), findsOneWidget);
    });

    testWidgets('shows error when password too short', (tester) async {
      await _setupDI();
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'user@example.com');
      await tester.enterText(fields.at(1), '123');
      await tester.enterText(fields.at(2), '123');

      await tester.tap(find.text('Create account').last);
      await tester.pumpAndSettle();

      expect(find.textContaining('6 characters'), findsOneWidget);
    });

    testWidgets('navigates back when Sign in link is tapped', (tester) async {
      await _setupDI();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => TextButton(
                onPressed: () => Navigator.of(ctx).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const RegisterScreen(),
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sign in'));
      await tester.pumpAndSettle();

      expect(find.text('Open'), findsOneWidget);
    });
  });
}
