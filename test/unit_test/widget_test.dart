import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clinic_go/features/doses/data/dose_log_repository.dart';
import 'package:clinic_go/features/doses/models/scheduled_dose.dart';
import 'package:clinic_go/features/doses/view_models/daily_doses_controller.dart';
import 'package:clinic_go/features/doses/views/medication_dashboard_view.dart';
import 'package:clinic_go/main.dart';
import 'package:clinic_go/ui/common/widgets/custom_search_bar.dart';
import 'package:clinic_go/ui/common/widgets/floating_bottom_nav_bar.dart';

void main() {
  group('ClinicGO', () {
    testWidgets('configures the main Material app shell', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const ClinicGO());

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));

      expect(materialApp.title, 'ClinicGO');
      expect(materialApp.debugShowCheckedModeBanner, isFalse);
      expect(materialApp.theme?.useMaterial3, isTrue);
      expect(find.byType(MainScreen), findsOneWidget);
    });
  });

  group('MainScreen', () {
    testWidgets('renders the home screen search bar', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: MainScreen()));

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(CustomSearchBar), findsOneWidget);
      expect(find.text('O que precisas?'), findsOneWidget);
    });

    testWidgets('shows today medication cards on the home screen', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: MainScreen()));

      expect(find.text('Today\'s medication plan'), findsOneWidget);
      expect(find.text('Lisinopril'), findsOneWidget);
      expect(find.text('Take'), findsWidgets);
      expect(find.text('Skip'), findsWidgets);
    });

    testWidgets('shows the five primary navigation actions', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: MainScreen()));

      expect(find.byType(FloatingBottomNavBar), findsOneWidget);
    });

    testWidgets(
      'keeps the search field text after interacting with navigation',
      (WidgetTester tester) async {
        await tester.pumpWidget(const MaterialApp(home: MainScreen()));

        await tester.enterText(find.byType(TextField), 'treino');
        await tester.pump();

        expect(find.text('treino'), findsOneWidget);
      },
    );
  });

  group('MedicationDashboardView', () {
    testWidgets('marks a dose as taken immediately and hides actions', (
      WidgetTester tester,
    ) async {
      final controller = DailyDosesController(
        repository: const NoopDoseLogRepository(),
        initialDoses: [
          ScheduledDose(
            id: 'dose-1',
            medicationId: 'med-1',
            medicationName: 'Lisinopril',
            dosage: '10 mg',
            instructions: 'After breakfast',
            scheduledTime: DateTime(2026, 4, 16, 8),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: MedicationDashboardView(controller: controller)),
        ),
      );

      await tester.tap(find.text('Take'));
      await tester.pump();

      expect(find.text('Taken'), findsOneWidget);
      expect(find.textContaining('Logged at'), findsOneWidget);
      expect(find.text('Take'), findsNothing);
      expect(find.text('Skip'), findsNothing);
    });

    testWidgets('reverts optimistic updates and shows snackbar on failure', (
      WidgetTester tester,
    ) async {
      final controller = DailyDosesController(
        repository: _FailingDoseLogRepository(),
        initialDoses: [
          ScheduledDose(
            id: 'dose-1',
            medicationId: 'med-1',
            medicationName: 'Lisinopril',
            dosage: '10 mg',
            instructions: 'After breakfast',
            scheduledTime: DateTime(2026, 4, 16, 8),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: MedicationDashboardView(controller: controller)),
        ),
      );

      await tester.tap(find.text('Take'));
      await tester.pumpAndSettle();

      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('Take'), findsOneWidget);
      expect(
        find.text('Network error. Please try logging your dose again.'),
        findsOneWidget,
      );
    });
  });
}

class _FailingDoseLogRepository implements DoseLogRepository {
  @override
  Future<void> logDose({
    required String medicationId,
    required DateTime scheduledTime,
    required DateTime loggedAt,
    required DoseStatus status,
  }) {
    return Future<void>.error(Exception('offline'));
  }
}
