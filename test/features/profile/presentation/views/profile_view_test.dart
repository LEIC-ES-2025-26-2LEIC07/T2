import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:clinic_go/features/auth/domain/auth_service.dart';
import 'package:clinic_go/features/profile/presentation/views/profile_view.dart';
import '../../../../helpers/mocks.dart';

Future<void> _setupDI({AuthService? authService}) async {
  await GetIt.I.reset();
  SharedPreferences.setMockInitialValues({});
  GetIt.I.registerSingleton<AuthService>(authService ?? AlwaysSuccessAuth());
}

Widget _buildApp() {
  return const MaterialApp(home: Scaffold(body: ProfileView()));
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
}

void main() {
  tearDown(() async => GetIt.I.reset());

  group('ProfileView — logged out', () {
    testWidgets('renders email and password fields', (tester) async {
      await _setupDI();
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextField, 'Email'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Password'), findsOneWidget);
    });

    testWidgets('renders "Continue with" divider', (tester) async {
      await _setupDI();
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Continue with'), findsOneWidget);
    });

    testWidgets('renders Forgot password and Create one now links', (
      tester,
    ) async {
      await _setupDI();
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Forgot password'), findsOneWidget);
      expect(find.textContaining("Don't have an account"), findsOneWidget);
      expect(find.textContaining('Create one now'), findsOneWidget);
    });

    testWidgets('renders Continue button', (tester) async {
      await _setupDI();
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Continue'), findsOneWidget);
    });

    testWidgets('shows error when Continue tapped with empty fields', (
      tester,
    ) async {
      await _setupDI();
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.textContaining('fill in'), findsOneWidget);
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
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.textContaining('valid email'), findsOneWidget);
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
        find.widgetWithText(TextField, 'Password'),
        'wrong',
      );
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Invalid credentials'), findsOneWidget);
    });

    testWidgets('shows error when Forgot password tapped with empty email', (
      tester,
    ) async {
      await _setupDI();
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Forgot password'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Enter your email'), findsOneWidget);
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
        await tester.tap(find.text('Forgot password'));
        await tester.pumpAndSettle();

        expect(find.textContaining('sent an email'), findsOneWidget);
      },
    );
  });

  group('ProfileView — logged in', () {
    testWidgets('renders user name uppercased', (tester) async {
      await _setupDI(authService: _LoggedInAuth());
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      expect(find.text('ALICE TEST'), findsOneWidget);
    });

    testWidgets('renders Edit and Logout buttons', (tester) async {
      await _setupDI(authService: _LoggedInAuth());
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Logout'), findsOneWidget);
    });

    testWidgets('renders profile field labels in view mode', (tester) async {
      await _setupDI(authService: _LoggedInAuth());
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Nome'), findsOneWidget);
      expect(find.text('Nascimento'), findsOneWidget);
      expect(find.text('Telefone'), findsOneWidget);
      expect(find.text('Preferências'), findsOneWidget);
    });

    testWidgets('shows email value in profile view', (tester) async {
      await _setupDI(authService: _LoggedInAuth());
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      expect(find.text('alice@example.com'), findsOneWidget);
    });

    testWidgets('tapping Edit switches to edit mode with Save and Cancel', (
      tester,
    ) async {
      await _setupDI(authService: _LoggedInAuth());
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      expect(find.text('Save'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('tapping Cancel reverts to view mode', (tester) async {
      await _setupDI(authService: _LoggedInAuth());
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Save'), findsNothing);
      expect(find.text('Cancel'), findsNothing);
    });

    testWidgets('edit mode shows text fields for profile fields', (
      tester,
    ) async {
      await _setupDI(authService: _LoggedInAuth());
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      // In edit mode, profile fields become TextFields with labelText
      expect(find.widgetWithText(TextField, 'Nome'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Telefone'), findsOneWidget);
    });

    testWidgets('successful logout shows info message', (tester) async {
      await _setupDI(authService: _LoggedInAuth());
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Logout'));
      await tester.pumpAndSettle();

      expect(find.textContaining('signed out'), findsOneWidget);
    });

    testWidgets('failed logout shows error message', (tester) async {
      await _setupDI(
        authService: _LoggedInAuth(signOutError: Exception('network')),
      );
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Logout'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Could not sign out'), findsOneWidget);
    });

    testWidgets('user with no name falls back to USER_TEST', (tester) async {
      await _setupDI(authService: _LoggedInAuth(metadata: const {}));
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      expect(find.text('USER_TEST'), findsOneWidget);
    });

    testWidgets('successful profile save exits edit mode', (tester) async {
      await _setupDI(authService: _LoggedInAuth());
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Save'), findsNothing);
    });

    testWidgets('failed profile save shows error message', (tester) async {
      await _setupDI(
        authService: _LoggedInAuth(updateError: Exception('server error')),
      );
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Something went wrong'), findsOneWidget);
    });
  });
}
