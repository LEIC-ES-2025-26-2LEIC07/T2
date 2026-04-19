import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:clinic_go/main.dart' as app;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Integration Test', () {
    testWidgets('boots the app and keeps core components wired together', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});

      // Modern mock app_links
      tester.binding.defaultBinaryMessenger.setMockStreamHandler(
        const EventChannel('com.llfbandit.app_links/events'),
        _MockStreamHandler(),
      );
      tester.binding.defaultBinaryMessenger.setMockStreamHandler(
        const EventChannel('com.llfbandit.app_links/messages'),
        _MockStreamHandler(),
      );

      try {
        await Supabase.initialize(
          url: const String.fromEnvironment(
            'NEXT_PUBLIC_SUPABASE_URL',
            defaultValue: 'https://test.supabase.co',
          ),
          anonKey: const String.fromEnvironment(
            'SB_PV_KEY',
            defaultValue: 'test-anon-key',
          ),
        );
      } catch (_) {
        // Already initialized
      }

      await app.main();
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
    });
  });
}

class _MockStreamHandler extends MockStreamHandler {
  @override
  void onListen(Object? arguments, MockStreamHandlerEventSink events) {}
  @override
  void onCancel(Object? arguments) {}
}
