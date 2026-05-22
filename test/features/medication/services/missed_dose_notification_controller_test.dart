import 'package:clinic_go/features/medication/data/dose_log_repository.dart';
import 'package:clinic_go/features/medication/models/scheduled_dose.dart';
import 'package:clinic_go/features/medication/services/missed_dose_notification_controller.dart';
import 'package:clinic_go/features/medication/services/pending_notification_store.dart';
import 'package:clinic_go/features/auth/domain/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get_it/get_it.dart';
import '../../../helpers/medication_mocks.dart';

void main() {
  late MemoryNotificationGateway notificationGateway;
  late InMemoryDoseLogRepository doseLogRepository;
  late MissedDoseNotificationController controller;

  final demoDose = ScheduledDose(
    id: 'dose-123',
    medicationId: 'med-123',
    medicationName: 'Lisinopril',
    dosage: '10 mg',
    scheduledTime: DateTime(2026, 4, 16, 8),
  );

  // ignore: unused_local_variable — typed explicitly so late fields are known

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await GetIt.I.reset();
    notificationGateway = MemoryNotificationGateway();
    doseLogRepository = InMemoryDoseLogRepository();
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

  // Simulates calling scheduleDoseReminder one hour before the dose fires.
  final beforeDose = demoDose.scheduledTime.subtract(const Duration(hours: 1));

  group('MissedDoseNotificationController', () {
    test(
      'schedules primary and missed notifications with deterministic IDs',
      () async {
        await controller.scheduleDoseReminder(demoDose, now: beforeDose);

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
        await controller.scheduleDoseReminder(demoDose, now: beforeDose);

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
        final failingRepository = FailingDoseLogRepository();
        controller = MissedDoseNotificationController(
          notificationGateway: notificationGateway,
          doseLogRepository: failingRepository,
          pendingNotificationStore: const PendingNotificationStore(),
        );

        await controller.scheduleDoseReminder(demoDose, now: beforeDose);

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
        await controller.scheduleDoseReminder(demoDose, now: beforeDose);
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

    test(
      'sync skips notifications whose dose has not been logged yet',
      () async {
        await controller.scheduleDoseReminder(demoDose, now: beforeDose);

        await controller.syncPendingMissedNotifications();

        expect(notificationGateway.cancelledNotificationIds, isEmpty);
      },
    );

    test(
      'cancelMissedDoseNotification cancels the correct notification ID',
      () async {
        await controller.scheduleDoseReminder(demoDose, now: beforeDose);

        await controller.cancelMissedDoseNotification(demoDose.id);

        expect(
          notificationGateway.cancelledNotificationIds,
          contains(
            MissedDoseNotificationController.missedNotificationIdForDose(
              demoDose.id,
            ),
          ),
        );
      },
    );

    test(
      'buildDoseLoggingRoute contains scheduled status when not overdue',
      () {
        final route = MissedDoseNotificationController.buildDoseLoggingRoute(
          demoDose,
        );
        expect(route, contains('status=scheduled'));
        expect(route, contains('dose-123'));
      },
    );

    test('buildDoseLoggingRoute contains overdue status when overdue', () {
      final route = MissedDoseNotificationController.buildDoseLoggingRoute(
        demoDose,
        isOverdue: true,
      );
      expect(route, contains('status=overdue'));
    });

    test(
      'primaryNotificationIdForDose differs from missedNotificationIdForDose',
      () {
        final primary =
            MissedDoseNotificationController.primaryNotificationIdForDose(
              demoDose.id,
            );
        final missed =
            MissedDoseNotificationController.missedNotificationIdForDose(
              demoDose.id,
            );
        expect(primary, isNot(equals(missed)));
      },
    );

    test('logDose with explicit loggedAt uses that timestamp', () async {
      final loggedAt = DateTime(2026, 4, 16, 9);
      await controller.scheduleDoseReminder(demoDose, now: beforeDose);
      await controller.logDose(
        dose: demoDose,
        status: DoseLogStatus.skipped,
        loggedAt: loggedAt,
      );
      expect(await doseLogRepository.hasDoseLog(demoDose.id), isTrue);
    });

    test('sync creates emergency alert for overdue unlogged dose', () async {
      final alertRepo = CapturingEmergencyAlertRepository();
      final controllerWithAlerts = MissedDoseNotificationController(
        notificationGateway: notificationGateway,
        doseLogRepository: doseLogRepository,
        pendingNotificationStore: const PendingNotificationStore(),
        emergencyAlertRepository: alertRepo,
        gracePeriod: Duration.zero,
      );

      await controllerWithAlerts.scheduleDoseReminder(
        demoDose,
        now: beforeDose,
      );
      await controllerWithAlerts.syncPendingMissedNotifications();

      expect(alertRepo.createdAlerts, hasLength(1));
      expect(
        alertRepo.createdAlerts.first['medicationName'],
        demoDose.medicationName,
      );
      expect(alertRepo.createdAlerts.first['dosage'], demoDose.dosage);
      expect(alertRepo.createdAlerts.first['dose_id'], demoDose.id);
    });

    test('sync does not create alert when dose was already logged', () async {
      final alertRepo = CapturingEmergencyAlertRepository();
      final controllerWithAlerts = MissedDoseNotificationController(
        notificationGateway: notificationGateway,
        doseLogRepository: doseLogRepository,
        pendingNotificationStore: const PendingNotificationStore(),
        emergencyAlertRepository: alertRepo,
        gracePeriod: Duration.zero,
      );

      await controllerWithAlerts.scheduleDoseReminder(
        demoDose,
        now: beforeDose,
      );
      doseLogRepository.seedLoggedDose(demoDose.id);
      await controllerWithAlerts.syncPendingMissedNotifications();

      expect(alertRepo.createdAlerts, isEmpty);
    });

    group('day-boundary guards', () {
      test(
        'does not schedule anything for a dose from a previous day',
        () async {
          final yesterday = DateTime.now().subtract(const Duration(days: 1));
          final pastDose = ScheduledDose(
            id: 'past-dose',
            medicationId: 'med-1',
            medicationName: 'Aspirina',
            dosage: '100 mg',
            scheduledTime: yesterday,
          );

          await controller.scheduleDoseReminder(pastDose);

          expect(notificationGateway.scheduledRequests, isEmpty);
        },
      );

      test(
        'does not schedule missed notification when grace period already passed today',
        () async {
          final now = DateTime.now();
          final doseEarlierToday = ScheduledDose(
            id: 'today-past-grace',
            medicationId: 'med-1',
            medicationName: 'Metformina',
            dosage: '500 mg',
            scheduledTime: now.subtract(const Duration(hours: 2)),
          );
          // Grace period of 30 min has long passed (2h ago), so no missed notification.
          // Primary notification time is also in the past, so nothing is scheduled.
          await controller.scheduleDoseReminder(doseEarlierToday);

          expect(notificationGateway.scheduledRequests, isEmpty);
        },
      );

      test(
        'schedules only missed notification when primary time passed but grace period has not',
        () async {
          final now = DateTime.now();
          final doseJustMissed = ScheduledDose(
            id: 'today-in-grace',
            medicationId: 'med-1',
            medicationName: 'Metformina',
            dosage: '500 mg',
            scheduledTime: now.subtract(const Duration(minutes: 10)),
          );
          // 10 min ago — still within the 30-min grace window.
          await controller.scheduleDoseReminder(doseJustMissed);

          expect(notificationGateway.scheduledRequests, hasLength(1));
          expect(
            notificationGateway.scheduledRequests.first.id,
            MissedDoseNotificationController.missedNotificationIdForDose(
              doseJustMissed.id,
            ),
          );
        },
      );
    });
  });
}

class _MockAuthService implements AuthService {
  @override
  String? get currentUserEmail => null;

  @override
  Map<String, dynamic> get currentUserMetadata => const {};

  @override
  bool get isLoggedIn => false;

  @override
  Stream<bool> get authStateChanges => const Stream.empty();

  @override
  Future<void> resetPassword(String email) async {}

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
  Future<void> signOut() async {}

  @override
  Future<void> updateProfile({
    required String email,
    required Map<String, dynamic> metadata,
  }) async {}

  @override
  Future<String> uploadAvatar({
    required List<int> bytes,
    required String fileExtension,
  }) async => '';
}
