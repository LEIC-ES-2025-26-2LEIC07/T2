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
          url:
              'https://sb_publishable_e-bQdp8wGizIL1py2JMrSg_3GZtj_Lz.supabase.co',
          anonKey: 'sb_secret_8-OsrH4yDDnRHgOHj4Ls3Q_HNovhjgC',
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
