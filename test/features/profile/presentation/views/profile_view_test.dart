import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:clinic_go/core/routing/app_router.dart';
import 'package:clinic_go/features/auth/domain/auth_service.dart';
import 'package:clinic_go/features/profile/presentation/views/profile_view.dart';
import '../../../../helpers/mocks.dart';

Future<void> _setupDI({AuthService? authService}) async {
  await GetIt.I.reset();
  SharedPreferences.setMockInitialValues({});
  GetIt.I.registerSingleton<AuthService>(authService ?? AlwaysSuccessAuth());
}

Widget _buildApp() {
  return MaterialApp(
    theme: ThemeData(splashFactory: NoSplash.splashFactory),
    home: Scaffold(body: ProfileView()),
    onGenerateRoute: (settings) {
      if (settings.name == AppRouter.login) {
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => Scaffold(body: Text(settings.arguments! as String)),
        );
      }
      return null;
    },
  );
}

class _LoggedInAuth implements AuthService {
  _LoggedInAuth({
    this.metadata = const {'name': 'Alice Test'},
    this.signOutError,
    this.updateError,
  });

  final Map<String, dynamic> metadata;
  final Object? signOutError;
  final Object? updateError;

  @override
  bool get isLoggedIn => true;

  @override
  String? get currentUserEmail => 'alice@example.com';

  @override
  Map<String, dynamic> get currentUserMetadata => metadata;

  @override
  Stream<bool> get authStateChanges => const Stream.empty();

  @override
  Future<void> signIn({
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> signUp({
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> signOut() async {
    if (signOutError != null) throw signOutError!;
  }

  @override
  Future<void> resetPassword(String email) async {}

  @override
  Future<void> updateProfile({
    required String email,
    required Map<String, dynamic> metadata,
  }) async {
    if (updateError != null) throw updateError!;
  }

  @override
  Future<String> uploadAvatar({
    required List<int> bytes,
    required String fileExtension,
  }) async => '';
}

void main() {
  tearDown(() async => GetIt.I.reset());

  group('ProfileView — logged out', () {
    testWidgets('renders email and password fields', (tester) async {
      await _setupDI();
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextField, 'Email'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Palavra-passe'), findsOneWidget);
    });

    testWidgets('renders "Continue with" divider', (tester) async {
      await _setupDI();
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Continuar com'), findsOneWidget);
    });

    testWidgets('renders Forgot password and Create one now links', (
      tester,
    ) async {
      await _setupDI();
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Esqueci-me da palavra-passe'), findsOneWidget);
      expect(find.textContaining("Não tens conta"), findsOneWidget);
      expect(find.textContaining('Cria uma agora'), findsOneWidget);
    });

    testWidgets('renders Continue button', (tester) async {
      await _setupDI();
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Continuar'), findsOneWidget);
    });

    testWidgets('shows error when Continue tapped with empty fields', (
      tester,
    ) async {
      await _setupDI();
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Preenche o email'), findsOneWidget);
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
        find.widgetWithText(TextField, 'Palavra-passe'),
        'secret',
      );
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();

      expect(find.textContaining('email válido'), findsOneWidget);
    });

    testWidgets('shows error on failed sign in', (tester) async {
      await _setupDI(authService: AlwaysFailAuth(error: Exception('bad')));
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'Email'),
        'user@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Palavra-passe'),
        'wrong',
      );
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Credenciais inválidas'), findsOneWidget);
    });

    testWidgets('shows error when Forgot password tapped with empty email', (
      tester,
    ) async {
      await _setupDI();
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Esqueci-me da palavra-passe'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Introduz o teu email'), findsOneWidget);
    });

    testWidgets(
      'shows success info when Forgot password tapped with valid email',
      (tester) async {
        await _setupDI();
        await tester.pumpWidget(_buildApp());
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextField, 'Email'),
          'user@example.com',
        );
        await tester.tap(find.text('Esqueci-me da palavra-passe'));
        await tester.pumpAndSettle();

        expect(find.textContaining('Enviámos um email'), findsOneWidget);
      },
    );
  });

  group('ProfileView — logged in', () {
    testWidgets('renders user name', (tester) async {
      await _setupDI(authService: _LoggedInAuth());
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Alice Test'), findsWidgets);
    });

    testWidgets('renders Editar perfil and Sair buttons', (tester) async {
      await _setupDI(authService: _LoggedInAuth());
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Editar perfil'), findsOneWidget);
      expect(find.text('Sair'), findsOneWidget);
    });

    testWidgets('renders profile field labels in view mode', (tester) async {
      await _setupDI(authService: _LoggedInAuth());
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      expect(find.text('NOME'), findsOneWidget);
      expect(find.text('EMAIL'), findsOneWidget);
    });

    testWidgets('shows email value in profile view', (tester) async {
      await _setupDI(authService: _LoggedInAuth());
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      expect(find.text('alice@example.com'), findsOneWidget);
    });

    testWidgets('tapping Editar perfil switches to edit mode', (tester) async {
      await _setupDI(authService: _LoggedInAuth());
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Editar perfil'));
      await tester.pumpAndSettle();

      expect(find.text('Guardar'), findsOneWidget);
      expect(find.text('Cancelar'), findsOneWidget);
    });

    testWidgets('tapping Cancelar reverts to view mode', (tester) async {
      await _setupDI(authService: _LoggedInAuth());
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Editar perfil'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(find.text('Editar perfil'), findsOneWidget);
      expect(find.text('Guardar'), findsNothing);
      expect(find.text('Cancelar'), findsNothing);
    });

    testWidgets('edit mode shows text fields for Nome and Email', (
      tester,
    ) async {
      await _setupDI(authService: _LoggedInAuth());
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Editar perfil'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextField, 'Nome'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Email'), findsOneWidget);
    });

    testWidgets('successful logout navigates to login', (tester) async {
      await _setupDI(authService: _LoggedInAuth());
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sair'));
      await tester.pumpAndSettle();

      expect(find.text('Sessão terminada com sucesso.'), findsOneWidget);
    });

    testWidgets('failed logout shows error message', (tester) async {
      await _setupDI(
        authService: _LoggedInAuth(signOutError: Exception('network')),
      );
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sair'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Não foi possível terminar a sessão'), findsOneWidget);
    });

    testWidgets('user with no name falls back to Utilizador', (tester) async {
      await _setupDI(authService: _LoggedInAuth(metadata: const {}));
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Utilizador'), findsWidgets);
    });

    testWidgets('successful profile save exits edit mode', (tester) async {
      await _setupDI(authService: _LoggedInAuth());
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Editar perfil'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      expect(find.text('Editar perfil'), findsOneWidget);
      expect(find.text('Guardar'), findsNothing);
    });

    testWidgets('failed profile save shows error message', (tester) async {
      await _setupDI(
        authService: _LoggedInAuth(updateError: Exception('server error')),
      );
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Editar perfil'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Ocorreu um erro'), findsOneWidget);
    });
  });
}
