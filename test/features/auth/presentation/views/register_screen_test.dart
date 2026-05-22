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

Widget _buildApp() => MaterialApp(
  theme: ThemeData(splashFactory: NoSplash.splashFactory),
  home: const RegisterScreen(),
  routes: {AppRouter.home: (_) => const Scaffold(body: Text('Home'))},
);

void main() {
  tearDown(() async => GetIt.I.reset());

  group('RegisterScreen', () {
    testWidgets('renders title and all 4 fields', (tester) async {
      await _setupDI();
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Criar conta'), findsWidgets);
      expect(find.text('1 DE 2'), findsNothing);
      expect(find.text('DATA DE NASCIMENTO'), findsNothing);
      // name, email, password, confirm
      expect(find.byType(TextField), findsNWidgets(4));
      expect(find.text('Concluir registo →'), findsOneWidget);
    });

    testWidgets('shows error when name is empty', (tester) async {
      await _setupDI();
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Concluir registo →'));
      await tester.pumpAndSettle();

      expect(find.textContaining('nome'), findsOneWidget);
    });

    testWidgets('shows error when passwords do not match', (tester) async {
      await _setupDI();
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'Maria Silva'); // name
      await tester.enterText(fields.at(1), 'maria@email.pt'); // email
      await tester.enterText(fields.at(2), 'password123'); // password
      await tester.enterText(fields.at(3), 'different456'); // confirm

      await tester.tap(find.text('Concluir registo →'));
      await tester.pumpAndSettle();

      expect(find.textContaining('coincidem'), findsOneWidget);
    });

    testWidgets('shows error when password is too short', (tester) async {
      await _setupDI();
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'Maria Silva');
      await tester.enterText(fields.at(1), 'maria@email.pt');
      await tester.enterText(fields.at(2), 'abc');
      await tester.enterText(fields.at(3), 'abc');

      await tester.tap(find.text('Concluir registo →'));
      await tester.pumpAndSettle();

      expect(find.textContaining('pelo menos 8'), findsAtLeastNWidgets(1));
    });

    testWidgets('back button pops the screen', (tester) async {
      await _setupDI();
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(splashFactory: NoSplash.splashFactory),
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => Navigator.of(ctx).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const RegisterScreen(),
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
          routes: {AppRouter.home: (_) => const Scaffold(body: Text('Home'))},
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Criar conta'), findsWidgets);

      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Open'), findsOneWidget);
    });
  });
}
