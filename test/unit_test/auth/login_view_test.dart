import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'package:clinic_go/data/repositories/auth_repository.dart';
import 'package:clinic_go/domain/models/user_model.dart';
import 'package:clinic_go/ui/auth/view_models/auth_view_model.dart';
import 'package:clinic_go/ui/auth/views/login_view.dart';

import 'login_view_test.mocks.dart';

const _fakeUser = UserModel(id: 'u1', email: 'user@test.com');

@GenerateMocks([AuthRepository])
void main() {
  late MockAuthRepository mockRepo;
  late StreamController<UserModel?> authStream;

  setUp(() {
    mockRepo = MockAuthRepository();
    authStream = StreamController<UserModel?>.broadcast();
    when(mockRepo.currentUser).thenReturn(null);
    when(mockRepo.authStateChanges).thenAnswer((_) => authStream.stream);
  });

  tearDown(() => authStream.close());

  /// Helper: pump the LoginView with a fresh AuthViewModel backed by [mockRepo].
  Future<void> pumpLogin(WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<AuthViewModel>(
        create: (_) => AuthViewModel(repo: mockRepo),
        child: const MaterialApp(home: LoginView()),
      ),
    );
    await tester.pump(); // settle initial state
  }

  // ─── Rendering ─────────────────────────────────────────────────────────────

  group('LoginView – rendering', () {
    testWidgets('shows ClinicGO brand text', (tester) async {
      await pumpLogin(tester);
      expect(find.text('ClinicGO'), findsOneWidget);
    });

    testWidgets('shows "Bem-vindo de volta" subtitle in sign-in mode', (
      tester,
    ) async {
      await pumpLogin(tester);
      expect(find.text('Bem-vindo de volta'), findsOneWidget);
    });

    testWidgets('shows email, password, and submit fields', (tester) async {
      await pumpLogin(tester);
      expect(find.byKey(const Key('email')), findsOneWidget);
      expect(find.byKey(const Key('password')), findsOneWidget);
      expect(find.byKey(const Key('submitButton')), findsOneWidget);
    });

    testWidgets('shows "Entrar" label on submit button', (tester) async {
      await pumpLogin(tester);
      expect(find.text('Entrar'), findsOneWidget);
    });

    testWidgets('shows toggle button with "Registar" text', (tester) async {
      await pumpLogin(tester);
      expect(find.byKey(const Key('toggleAuthMode')), findsOneWidget);
      // 'Registar' is in a RichText TextSpan, not a plain Text widget.
      expect(
        find.byWidgetPredicate(
          (w) => w is RichText && w.text.toPlainText().contains('Registar'),
        ),
        findsWidgets,
      );
    });
  });

  // ─── Toggle sign-in/sign-up ────────────────────────────────────────────────

  group('LoginView – toggle mode', () {
    testWidgets('tapping toggleAuthMode switches to sign-up mode', (
      tester,
    ) async {
      await pumpLogin(tester);
      await tester.tap(find.byKey(const Key('toggleAuthMode')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('fullName')), findsOneWidget);
      expect(find.byKey(const Key('phone')), findsOneWidget);
      expect(find.text('Criar conta'), findsOneWidget);
    });

    testWidgets('tapping toggle twice returns to sign-in mode', (tester) async {
      await pumpLogin(tester);

      // First tap: switch to sign-up mode.
      final toggle = find.byKey(const Key('toggleAuthMode'));
      await tester.ensureVisible(toggle);
      await tester.tap(toggle);
      await tester.pumpAndSettle();

      // Second tap: switch back to sign-in mode.
      await tester.ensureVisible(toggle);
      await tester.tap(toggle, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('fullName')), findsNothing);
      expect(find.text('Entrar'), findsOneWidget);
    });

    testWidgets('sign-up subtitle shows "Cria a tua conta"', (tester) async {
      await pumpLogin(tester);
      await tester.tap(find.byKey(const Key('toggleAuthMode')));
      await tester.pumpAndSettle();
      expect(find.text('Cria a tua conta'), findsOneWidget);
    });
  });

  // ─── Password visibility toggle ────────────────────────────────────────────

  group('LoginView – password visibility', () {
    testWidgets('password is hidden by default', (tester) async {
      await pumpLogin(tester);
      // TextFormField wraps a TextField; access obscureText via the TextField.
      final field = tester.widget<TextField>(
        find.descendant(
          of: find.byKey(const Key('password')),
          matching: find.byType(TextField),
        ),
      );
      expect(field.obscureText, isTrue);
    });

    testWidgets('tapping visibility icon reveals password', (tester) async {
      await pumpLogin(tester);
      await tester.tap(find.byIcon(Icons.visibility_off_outlined));
      await tester.pump();

      final field = tester.widget<TextField>(
        find.descendant(
          of: find.byKey(const Key('password')),
          matching: find.byType(TextField),
        ),
      );
      expect(field.obscureText, isFalse);
    });
  });

  // ─── Form validation ────────────────────────────────────────────────────────

  group('LoginView – form validation', () {
    testWidgets('shows error when email is empty and form submitted', (
      tester,
    ) async {
      await pumpLogin(tester);
      await tester.tap(find.byKey(const Key('submitButton')));
      await tester.pump();

      expect(find.text('Insere o teu email'), findsOneWidget);
    });

    testWidgets('shows error for invalid email format', (tester) async {
      await pumpLogin(tester);
      await tester.enterText(find.byKey(const Key('email')), 'notanemail');
      await tester.tap(find.byKey(const Key('submitButton')));
      await tester.pump();

      expect(find.text('Email inválido'), findsOneWidget);
    });

    testWidgets('shows error when password is empty', (tester) async {
      await pumpLogin(tester);
      await tester.enterText(find.byKey(const Key('email')), 'a@b.com');
      await tester.tap(find.byKey(const Key('submitButton')));
      await tester.pump();

      expect(find.text('Insere a tua palavra-passe'), findsOneWidget);
    });

    testWidgets('shows short-password error in sign-up mode', (tester) async {
      await pumpLogin(tester);
      await tester.tap(find.byKey(const Key('toggleAuthMode')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('fullName')), 'Alice');
      await tester.enterText(find.byKey(const Key('email')), 'a@b.com');
      await tester.enterText(find.byKey(const Key('password')), '123');
      await tester.tap(find.byKey(const Key('submitButton')));
      await tester.pump();

      expect(find.text('Mínimo 6 caracteres'), findsOneWidget);
    });

    testWidgets('shows fullName required error in sign-up mode', (
      tester,
    ) async {
      await pumpLogin(tester);
      await tester.tap(find.byKey(const Key('toggleAuthMode')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('email')), 'a@b.com');
      await tester.enterText(find.byKey(const Key('password')), 'pass123');
      // leave fullName empty
      await tester.tap(find.byKey(const Key('submitButton')));
      await tester.pump();

      expect(find.text('Insere o teu nome'), findsOneWidget);
    });
  });

  // ─── signIn interaction ────────────────────────────────────────────────────

  group('LoginView – signIn interaction', () {
    testWidgets('shows loading indicator while signing in', (tester) async {
      final completer = Completer<UserModel>();
      when(
        mockRepo.signIn(
          email: anyNamed('email'),
          password: anyNamed('password'),
        ),
      ).thenAnswer((_) => completer.future);

      await pumpLogin(tester);
      await tester.enterText(find.byKey(const Key('email')), 'a@b.com');
      await tester.enterText(find.byKey(const Key('password')), 'pass123');
      await tester.tap(find.byKey(const Key('submitButton')));
      await tester.pump(); // start signIn, show loading

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      completer.complete(_fakeUser);
      await tester.pumpAndSettle();
    });

    testWidgets('shows snackbar on AuthException', (tester) async {
      when(
        mockRepo.signIn(
          email: anyNamed('email'),
          password: anyNamed('password'),
        ),
      ).thenThrow(const AuthException('Email ou palavra-passe incorretos.'));

      await pumpLogin(tester);
      await tester.enterText(find.byKey(const Key('email')), 'bad@b.com');
      await tester.enterText(find.byKey(const Key('password')), 'wrong');
      await tester.tap(find.byKey(const Key('submitButton')));
      await tester.pumpAndSettle();

      expect(find.text('Email ou palavra-passe incorretos.'), findsOneWidget);
    });

    testWidgets('submit button is disabled while loading', (tester) async {
      final completer = Completer<UserModel>();
      when(
        mockRepo.signIn(
          email: anyNamed('email'),
          password: anyNamed('password'),
        ),
      ).thenAnswer((_) => completer.future);

      await pumpLogin(tester);
      await tester.enterText(find.byKey(const Key('email')), 'a@b.com');
      await tester.enterText(find.byKey(const Key('password')), 'pass123');
      await tester.tap(find.byKey(const Key('submitButton')));
      await tester.pump();

      final btn = tester.widget<ElevatedButton>(
        find.byKey(const Key('submitButton')),
      );
      expect(btn.onPressed, isNull); // disabled

      completer.complete(_fakeUser);
      await tester.pumpAndSettle();
    });
  });
}
