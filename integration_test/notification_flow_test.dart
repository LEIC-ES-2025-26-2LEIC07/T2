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

        // Initialize Supabase with mock or real dev keys (using the ones from main.dart)
        try {
          await Supabase.initialize(
            url: 'https://pizwimuaqaafcgfibkdy.supabase.co',
            anonKey: 'sb_secret_keDm_RYq9eICBxw1Pvty8g_5Wf3E7I5',
          );
        } catch (_) {
          // Already initialized
        }

        // Start the app
        app.main();
        await tester.pumpAndSettle();

        // Verify we are on the Home screen
        expect(find.text('Bem-vindo à ClinicGO!'), findsOneWidget);
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
