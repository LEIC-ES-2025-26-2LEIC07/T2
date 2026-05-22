import 'package:clinic_go/features/medication/data/dose_log_repository.dart';
import 'package:clinic_go/features/medication/models/scheduled_dose.dart';
import 'package:clinic_go/features/medication/presentation/views/dose_logging_screen.dart';
import 'package:clinic_go/features/medication/services/missed_dose_notification_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockMissedDoseNotificationController extends Mock
    implements MissedDoseNotificationController {}

class FakeScheduledDose extends Fake implements ScheduledDose {}

final _dose = ScheduledDose(
  id: 'dose-1',
  medicationId: 'med-1',
  medicationName: 'Aspirin',
  dosage: '100mg',
  scheduledTime: DateTime(2026, 5, 18, 8, 0),
);

Widget _buildScreen({
  required MissedDoseNotificationController controller,
  bool isOverdue = false,
}) => MaterialApp(
  theme: ThemeData(splashFactory: NoSplash.splashFactory),
  home: DoseLoggingScreen(
    dose: _dose,
    controller: controller,
    isOverdue: isOverdue,
  ),
);

void main() {
  late MockMissedDoseNotificationController controller;

  setUpAll(() {
    registerFallbackValue(FakeScheduledDose());
    registerFallbackValue(DoseLogStatus.taken);
  });

  setUp(() {
    controller = MockMissedDoseNotificationController();
  });

  void stubLogDoseSuccess() {
    when(
      () => controller.logDose(
        dose: any(named: 'dose'),
        status: any(named: 'status'),
        loggedAt: any(named: 'loggedAt'),
      ),
    ).thenAnswer((_) async {});
  }

  void stubLogDoseFailure() {
    when(
      () => controller.logDose(
        dose: any(named: 'dose'),
        status: any(named: 'status'),
        loggedAt: any(named: 'loggedAt'),
      ),
    ).thenThrow(Exception('Network error'));
  }

  group('DoseLoggingScreen – rendering', () {
    testWidgets('renders medication name, dosage and action buttons', (
      tester,
    ) async {
      stubLogDoseSuccess();
      await tester.pumpWidget(_buildScreen(controller: controller));
      await tester.pumpAndSettle();

      expect(find.text('Aspirin'), findsOneWidget);
      expect(find.textContaining('100mg'), findsOneWidget);
      expect(find.text('Mark as Taken'), findsOneWidget);
      expect(find.text('Skip Dose'), findsOneWidget);
    });

    testWidgets('shows overdue banner when isOverdue is true', (tester) async {
      await tester.pumpWidget(
        _buildScreen(controller: controller, isOverdue: true),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('overdue'), findsOneWidget);
    });

    testWidgets('does not show overdue banner when isOverdue is false', (
      tester,
    ) async {
      await tester.pumpWidget(_buildScreen(controller: controller));
      await tester.pumpAndSettle();

      expect(find.textContaining('overdue'), findsNothing);
    });
  });

  group('DoseLoggingScreen – mark as taken', () {
    testWidgets('shows success state and snackbar after marking taken', (
      tester,
    ) async {
      stubLogDoseSuccess();
      await tester.pumpWidget(_buildScreen(controller: controller));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Mark as Taken'));
      await tester.pumpAndSettle();

      expect(find.text('Done'), findsOneWidget);
      expect(find.text('Mark as Taken'), findsNothing);
      expect(find.text('Skip Dose'), findsNothing);
      expect(find.text('Dose marked as taken.'), findsOneWidget);
    });
  });

  group('DoseLoggingScreen – skip dose', () {
    testWidgets('shows success state and snackbar after skipping', (
      tester,
    ) async {
      stubLogDoseSuccess();
      await tester.pumpWidget(_buildScreen(controller: controller));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Skip Dose'));
      await tester.pumpAndSettle();

      expect(find.text('Done'), findsOneWidget);
      expect(find.text('Mark as Taken'), findsNothing);
      expect(find.text('Skip Dose'), findsNothing);
      expect(find.text('Dose marked as skipped.'), findsOneWidget);
    });
  });

  group('DoseLoggingScreen – error handling', () {
    testWidgets('log failure shows error snackbar and rolls back buttons', (
      tester,
    ) async {
      stubLogDoseFailure();
      await tester.pumpWidget(_buildScreen(controller: controller));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Mark as Taken'));
      await tester.pumpAndSettle();

      expect(
        find.text('We could not save this dose right now. Please try again.'),
        findsOneWidget,
      );
      expect(find.text('Mark as Taken'), findsOneWidget);
      expect(find.text('Skip Dose'), findsOneWidget);
      expect(find.text('Done'), findsNothing);
    });
  });
}
