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

Widget _buildApp({String? successMessage}) {
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
    home: LoginScreen(successMessage: successMessage),
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

    testWidgets('renders hero, Entrar button and ESQUECI-ME link', (
      tester,
    ) async {
      await _setupDI();
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      expect(find.text('ClinicGO'), findsOneWidget);
      expect(find.text('BEM-VINDA DE VOLTA'), findsOneWidget);
      expect(find.text('Entrar'), findsOneWidget);
      expect(find.text('ESQUECI-ME'), findsOneWidget);
    });

    testWidgets('renders criar conta card', (tester) async {
      await _setupDI();
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      expect(find.text('NOVO POR AQUI?'), findsOneWidget);
      expect(find.text('Cria a tua conta'), findsOneWidget);
      expect(find.text('CRIAR'), findsOneWidget);
    });

    testWidgets('shows error when Entrar tapped with empty fields', (
      tester,
    ) async {
      await _setupDI();
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Entrar'));
      await tester.pumpAndSettle();

      expect(find.textContaining('email e a password'), findsOneWidget);
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
      await tester.tap(find.text('Entrar'));
      await tester.pumpAndSettle();

      expect(find.textContaining('email válido'), findsOneWidget);
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
      await tester.tap(find.text('Entrar'));
      await tester.pumpAndSettle();

      expect(find.textContaining('possível iniciar sessão'), findsOneWidget);
    });

    testWidgets('shows success banner when successMessage provided', (
      tester,
    ) async {
      await _setupDI();
      await tester.pumpWidget(
        _buildApp(successMessage: 'Sessão terminada com sucesso.'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sessão terminada com sucesso.'), findsOneWidget);
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
      await tester.tap(find.text('Entrar'));
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('CRIAR button navigates to register screen', (tester) async {
      await _setupDI();
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('CRIAR'));
      await tester.pumpAndSettle();

      expect(find.text('Register'), findsOneWidget);
    });
  });
}
