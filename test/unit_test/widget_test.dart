import 'package:clinic_go/features/medication/data/dose_log_repository.dart';
import 'package:clinic_go/features/medication/models/scheduled_dose.dart';
import 'package:clinic_go/features/medication/services/local_notification_gateway.dart';
import 'package:clinic_go/features/medication/services/missed_dose_notification_controller.dart';
import 'package:clinic_go/features/medication/services/pending_notification_store.dart';
import 'package:clinic_go/features/home/presentation/views/main_screen.dart';
import 'package:clinic_go/features/auth/domain/auth_service.dart';
import 'package:clinic_go/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get_it/get_it.dart';

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

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await GetIt.I.reset();
    notificationGateway = _MemoryNotificationGateway();
    doseLogRepository = _InMemoryDoseLogRepository();
    controller = MissedDoseNotificationController(
      notificationGateway: notificationGateway,
      doseLogRepository: doseLogRepository,
      pendingNotificationStore: const PendingNotificationStore(),
    );

    GetIt.I.registerSingleton<MissedDoseNotificationController>(controller);
    GetIt.I.registerSingleton<AuthService>(_MockAuthService());
  });

  tearDown(() async {
    await GetIt.I.reset();
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
      await tester.pumpWidget(const ClinicGO());

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));

      expect(materialApp.title, 'ClinicGO');
      expect(materialApp.debugShowCheckedModeBanner, isFalse);
      expect(materialApp.theme?.useMaterial3, isTrue);
      expect(find.byType(MainScreen), findsOneWidget);
    });

    testWidgets('renders the home screen search bar', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const ClinicGO());

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.text('O que precisas?'), findsOneWidget);
      expect(find.text('Open overdue dose'), findsOneWidget);
    });

    testWidgets(
      'deep-links to the dose logging screen with overdue messaging',
      (WidgetTester tester) async {
        await tester.pumpWidget(const ClinicGO());

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

      // Update the mock in DI
      GetIt.I.unregister<MissedDoseNotificationController>();
      GetIt.I.registerSingleton<MissedDoseNotificationController>(controller);

      await tester.pumpWidget(const ClinicGO());

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
}

class _MockAuthService implements AuthService {
  @override
  String? get currentUserEmail => null;

  @override
  bool get isLoggedIn => false;

  @override
  Future<void> resetPassword(String email) async {}

  @override
  Future<void> signIn({
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> signOut() async {}
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
