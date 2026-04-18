import 'package:clinic_go/features/medication/data/dose_log_repository.dart';
import 'package:clinic_go/features/medication/models/scheduled_dose.dart';
import 'package:clinic_go/features/medication/services/local_notification_gateway.dart';
import 'package:clinic_go/features/medication/services/missed_dose_notification_controller.dart';
import 'package:clinic_go/features/medication/services/pending_notification_store.dart';
import 'package:clinic_go/features/home/presentation/views/main_screen.dart';
import 'package:clinic_go/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clinic_go/ui/doses/data/dose_log_repository.dart';
import 'package:clinic_go/ui/doses/models/scheduled_dose.dart';
import 'package:clinic_go/ui/doses/view_models/daily_doses_controller.dart';
import 'package:clinic_go/ui/doses/views/medication_dashboard_view.dart';
import 'package:clinic_go/main.dart';
import 'package:clinic_go/ui/common/widgets/custom_search_bar.dart';
import 'package:clinic_go/ui/common/widgets/floating_bottom_nav_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late _MemoryNotificationGateway notificationGateway;
  late _InMemoryDoseLogRepository doseLogRepository;
  late MissedDoseNotificationController controller;

  final demoDose = ScheduledDose(
    id: 'dose-123',
    medicationId: 'med-123',
    medicationName: 'Lisinopril',
    dosage: '10 mg',
    scheduledTime: DateTime(2026, 4, 16, 8),
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    notificationGateway = _MemoryNotificationGateway();
    doseLogRepository = _InMemoryDoseLogRepository();
    controller = MissedDoseNotificationController(
      notificationGateway: notificationGateway,
      doseLogRepository: doseLogRepository,
      pendingNotificationStore: const PendingNotificationStore(),
    );
  });

  group('MissedDoseNotificationController', () {
    test(
      'schedules primary and missed notifications with deterministic IDs',
      () async {
        await controller.scheduleDoseReminder(demoDose);

        expect(notificationGateway.scheduledRequests, hasLength(2));
        expect(
          notificationGateway.scheduledRequests.map((request) => request.id),
          containsAll([
            MissedDoseNotificationController.primaryNotificationIdForDose(
              demoDose.id,
            ),
            MissedDoseNotificationController.missedNotificationIdForDose(
              demoDose.id,
            ),
          ]),
        );
        expect(
          notificationGateway.scheduledRequests.last.scheduledTime,
          demoDose.scheduledTime.add(const Duration(minutes: 30)),
        );
        expect(
          notificationGateway.scheduledRequests.last.payload,
          contains('"status":"overdue"'),
        );
      },
    );

    test(
      'cancels the pending missed notification after logging a dose',
      () async {
        await controller.scheduleDoseReminder(demoDose);

        await controller.logDose(dose: demoDose, status: DoseLogStatus.taken);

        expect(
          notificationGateway.cancelledNotificationIds,
          contains(
            MissedDoseNotificationController.missedNotificationIdForDose(
              demoDose.id,
            ),
          ),
        );
        expect(await doseLogRepository.hasDoseLog(demoDose.id), isTrue);
      },
    );

    test(
      'keeps the pending missed notification when the dose log insert fails',
      () async {
        final failingRepository = _FailingDoseLogRepository();
        controller = MissedDoseNotificationController(
          notificationGateway: notificationGateway,
          doseLogRepository: failingRepository,
          pendingNotificationStore: const PendingNotificationStore(),
        );

        await controller.scheduleDoseReminder(demoDose);

        await expectLater(
          controller.logDose(dose: demoDose, status: DoseLogStatus.taken),
          throwsA(isA<StateError>()),
        );

        expect(notificationGateway.cancelledNotificationIds, isEmpty);
        final preferences = await SharedPreferences.getInstance();
        expect(
          preferences.getStringList('pending_missed_dose_notifications'),
          isNotEmpty,
        );
      },
    );

    test(
      'startup sync cancels locally pending missed notifications logged on another device',
      () async {
        await controller.scheduleDoseReminder(demoDose);
        doseLogRepository.seedLoggedDose(demoDose.id);

        await controller.syncPendingMissedNotifications();

        expect(
          notificationGateway.cancelledNotificationIds,
          contains(
            MissedDoseNotificationController.missedNotificationIdForDose(
              demoDose.id,
            ),
          ),
        );
        final preferences = await SharedPreferences.getInstance();
        expect(
          preferences.getStringList('pending_missed_dose_notifications'),
          isEmpty,
        );
      },
    );
  });

  group('ClinicGO', () {
    testWidgets('configures the main Material app shell', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(ClinicGO(notificationController: controller));

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));

      expect(materialApp.title, 'ClinicGO');
      expect(materialApp.debugShowCheckedModeBanner, isFalse);
      expect(materialApp.theme?.useMaterial3, isTrue);
      expect(find.byType(MainScreen), findsOneWidget);
    });

    testWidgets('renders the home screen search bar', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(ClinicGO(notificationController: controller));

      expect(find.byType(Scaffold), findsOneWidget);
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
      expect(find.text('Open overdue dose'), findsOneWidget);
    });

    testWidgets(
      'deep-links to the dose logging screen with overdue messaging',
      (WidgetTester tester) async {
        await tester.pumpWidget(ClinicGO(notificationController: controller));

        await tester.tap(find.text('Open overdue dose'));
        await tester.pumpAndSettle();

        expect(find.text('Dose Logging'), findsOneWidget);
        expect(
          find.text(
            'This dose is overdue. Please log whether it was taken or skipped.',
          ),
          findsOneWidget,
        );
        expect(find.text('Mark as Taken'), findsOneWidget);
      },
    );

    testWidgets('shows an error snackbar if dose logging fails', (
      WidgetTester tester,
    ) async {
      controller = MissedDoseNotificationController(
        notificationGateway: notificationGateway,
        doseLogRepository: _FailingDoseLogRepository(),
        pendingNotificationStore: const PendingNotificationStore(),
      );

      await tester.pumpWidget(ClinicGO(notificationController: controller));

      await tester.tap(find.text('Open overdue dose'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Mark as Taken'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.text('We could not save this dose right now. Please try again.'),
        findsOneWidget,
      );
    });
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

class _MemoryNotificationGateway implements LocalNotificationGateway {
  final List<NotificationRequest> scheduledRequests = [];
  final List<int> cancelledNotificationIds = [];

  @override
  Future<void> cancel(int notificationId) async {
    cancelledNotificationIds.add(notificationId);
  }

  @override
  Future<void> schedule(NotificationRequest request) async {
    scheduledRequests.add(request);
  }
}

class _InMemoryDoseLogRepository implements DoseLogRepository {
  final Set<String> _loggedDoseIds = <String>{};

  @override
  Future<bool> hasDoseLog(String doseId) async =>
      _loggedDoseIds.contains(doseId);

  @override
  Future<void> insertDoseLog({
    required ScheduledDose dose,
    required DoseLogStatus status,
    required DateTime loggedAt,
  }) async {
    _loggedDoseIds.add(dose.id);
  }

  void seedLoggedDose(String doseId) {
    _loggedDoseIds.add(doseId);
  }
}

class _FailingDoseLogRepository implements DoseLogRepository {
  @override
  Future<bool> hasDoseLog(String doseId) async => false;

  @override
  Future<void> insertDoseLog({
    required ScheduledDose dose,
    required DoseLogStatus status,
    required DateTime loggedAt,
  }) {
    throw StateError('insert failed');
  }
}
