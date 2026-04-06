import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:clinic_go/ui/auth/view_models/auth_view_model.dart';
import 'package:clinic_go/ui/auth/views/auth_wrapper.dart';
import 'package:clinic_go/main.dart';
import 'package:clinic_go/ui/core/themes/app_colors.dart';

/// Boots Supabase exactly once for the test session.
bool _supabaseReady = false;

Future<void> _bootSupabase() async {
  if (_supabaseReady) return;
  await dotenv.load(fileName: '.env');
  try {
    await Supabase.initialize(
      url: dotenv.env['NEXT_PUBLIC_SUPABASE_URL']!,
      anonKey: dotenv.env['SB_PV_KEY']!,
    );
  } catch (_) {
    // Already initialized (test runner re-uses the same isolate).
  }
  _supabaseReady = true;
}

/// Minimal app wrapper that skips dotenv/Supabase init
/// (already done in [_bootSupabase]) and provides [AuthViewModel].
Widget _testApp({required Widget home}) {
  return MultiProvider(
    providers: [ChangeNotifierProvider(create: (_) => AuthViewModel())],
    child: MaterialApp(
      title: 'ClinicGO',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primaryColor),
      ),
      home: home,
    ),
  );
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});

    // Silence platform channels used by Supabase deep-link handling.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('com.llfbandit.app_links/events'),
          (call) async => null,
        );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('com.llfbandit.app_links/messages'),
          (call) async => null,
        );

    await _bootSupabase();
  });

  group('Smoke Test', () {
    testWidgets('Unauthenticated user sees the login screen on cold start', (
      tester,
    ) async {
      await tester.pumpWidget(
        _testApp(home: const AuthWrapper(authenticatedChild: MainScreen())),
      );

      // Let the AuthViewModel resolve the initial auth state.
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      // Without a session the app should show the login form.
      expect(find.byKey(const Key('email')), findsOneWidget);
      expect(find.byKey(const Key('password')), findsOneWidget);
      expect(find.byKey(const Key('submitButton')), findsOneWidget);
    });

    testWidgets('Login screen toggles to sign-up mode', (tester) async {
      await tester.pumpWidget(
        _testApp(home: const AuthWrapper(authenticatedChild: MainScreen())),
      );

      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Tap the toggle button to switch to sign-up.
      await tester.tap(find.byKey(const Key('toggleAuthMode')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('fullName')), findsOneWidget);
      expect(find.byKey(const Key('phone')), findsOneWidget);
    });
  });
}
