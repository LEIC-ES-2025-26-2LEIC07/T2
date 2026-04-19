import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:clinic_go/main.dart' as app;
import 'package:clinic_go/features/medication/presentation/views/dose_logging_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Notification Flow Integration Test', () {
    testWidgets(
      'Verify navigation to DoseLoggingScreen from notification-like action',
      (WidgetTester tester) async {
        // Mock shared preferences
        SharedPreferences.setMockInitialValues({});

        tester.binding.defaultBinaryMessenger.setMockStreamHandler(
          const EventChannel('com.llfbandit.app_links/events'),
          _MockStreamHandler(),
        );
        tester.binding.defaultBinaryMessenger.setMockStreamHandler(
          const EventChannel('com.llfbandit.app_links/messages'),
          _MockStreamHandler(),
        );

        // Initialize Supabase with mock or real dev keys (using the ones from main.dart)
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

        // Start the app
        await app.main();
        await tester.pump();
        await tester.pump(const Duration(seconds: 2));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.home_outlined));
        await tester.pumpAndSettle();

        // Verify we are on the Home screen
        expect(find.text('Welcome to ClinicGO!'), findsOneWidget);
        expect(find.text('Upcoming dose'), findsOneWidget);

        // Find the button that simulates opening an overdue dose (notification behavior)
        final openDoseButton = find.text('Open overdue dose');
        expect(openDoseButton, findsOneWidget);

        // Tap the button
        await tester.tap(openDoseButton);

        // Wait for navigation animation
        await tester.pumpAndSettle();

        // Verify we have navigated to the DoseLoggingScreen
        expect(find.byType(DoseLoggingScreen), findsOneWidget);
        expect(
          find.text('Lisinopril'),
          findsOneWidget,
        ); // Medication from demo dose
        expect(find.text('Dose Logging'), findsOneWidget);

        // Verify the "Overdue" status is shown
        expect(
          find.textContaining(RegExp('overdue', caseSensitive: false)),
          findsWidgets,
        );
      },
    );
  });
}

class _MockStreamHandler extends MockStreamHandler {
  @override
  void onListen(Object? arguments, MockStreamHandlerEventSink events) {}
  @override
  void onCancel(Object? arguments) {}
}
