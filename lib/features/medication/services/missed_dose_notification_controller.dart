import 'package:flutter/foundation.dart';

import '../data/dose_log_repository.dart';
import '../data/medication_repository.dart';
import '../models/notification_payload.dart';
import '../models/pending_missed_dose_notification.dart';
import '../models/scheduled_dose.dart';
import 'dose_scheduling_service.dart';
import '../../auth/domain/auth_service.dart';
import '../../emergency_alerts/data/emergency_alert_repository.dart';
import 'local_notification_gateway.dart';
import 'pending_notification_store.dart';

class MissedDoseNotificationController {
  MissedDoseNotificationController({
    required LocalNotificationGateway notificationGateway,
    required DoseLogRepository doseLogRepository,
    required PendingNotificationStore pendingNotificationStore,
    MedicationRepository? medicationRepository,
    DoseSchedulingService? schedulingService,
    AuthService? authService,
    EmergencyAlertRepository? emergencyAlertRepository,
    this.gracePeriod = const Duration(minutes: 30),
  }) : _notificationGateway = notificationGateway,
       _doseLogRepository = doseLogRepository,
       _pendingNotificationStore = pendingNotificationStore,
       _medicationRepository = medicationRepository,
       _schedulingService = schedulingService,
       _authService = authService,
       _emergencyAlertRepository = emergencyAlertRepository;

  final LocalNotificationGateway _notificationGateway;
  final DoseLogRepository _doseLogRepository;
  final PendingNotificationStore _pendingNotificationStore;
  final MedicationRepository? _medicationRepository;
  final DoseSchedulingService? _schedulingService;
  final AuthService? _authService;
  final EmergencyAlertRepository? _emergencyAlertRepository;
  final Duration gracePeriod;

  Future<void> scheduleDoseReminder(ScheduledDose dose) async {
    final primaryPayload = NotificationPayload(
      route: buildDoseLoggingRoute(dose),
      status: 'scheduled',
      doseId: dose.id,
    );
    final missedPayload = NotificationPayload(
      route: buildDoseLoggingRoute(dose, isOverdue: true),
      status: 'overdue',
      doseId: dose.id,
    );

    await _notificationGateway.schedule(
      NotificationRequest(
        id: primaryNotificationIdForDose(dose.id),
        title: 'Time for Medication',
        body: 'Take ${dose.dosage} of ${dose.medicationName}',
        scheduledTime: dose.scheduledTime,
        payload: primaryPayload.encode(),
      ),
    );

    final missedScheduledTime = dose.scheduledTime.add(gracePeriod);
    final missedNotificationId = missedNotificationIdForDose(dose.id);
    await _notificationGateway.schedule(
      NotificationRequest(
        id: missedNotificationId,
        title: 'Missed Medication',
        body:
            'You are ${gracePeriod.inMinutes} mins late for ${dose.medicationName}',
        scheduledTime: missedScheduledTime,
        payload: missedPayload.encode(),
      ),
    );

    await _pendingNotificationStore.upsert(
      PendingMissedDoseNotification(
        dose: dose,
        notificationId: missedNotificationId,
        scheduledTime: missedScheduledTime,
      ),
    );
  }

  Future<void> refreshScheduledMedicationReminders({
    Duration horizon = const Duration(days: 14),
  }) async {
    final authService = _authService;
    final medicationRepository = _medicationRepository;
    final schedulingService = _schedulingService;

    if (authService == null ||
        medicationRepository == null ||
        schedulingService == null ||
        !authService.isLoggedIn) {
      return;
    }

    final medications = await medicationRepository.fetchMedications();
    final upcomingDoses = <ScheduledDose>[];

    for (final medication in medications) {
      final reminders = medication.reminders;
      if (!medication.isActive || reminders == null) {
        continue;
      }

      upcomingDoses.addAll(
        schedulingService.calculateUpcomingDoses(
          medication,
          reminders,
          duration: horizon,
        ),
      );
    }

    for (final dose in upcomingDoses) {
      await scheduleDoseReminder(dose);
    }
  }

  Future<void> logDose({
    required ScheduledDose dose,
    required DoseLogStatus status,
    DateTime? loggedAt,
  }) async {
    final timestamp = loggedAt ?? DateTime.now();
    await _doseLogRepository.insertDoseLog(
      dose: dose,
      status: status,
      loggedAt: timestamp,
    );

    try {
      await _notificationGateway.cancel(primaryNotificationIdForDose(dose.id));
      await cancelMissedDoseNotification(dose.id);
    } catch (error, stackTrace) {
      debugPrint('Failed to cancel notifications for dose ${dose.id}: $error');
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'missed_dose_notification_controller',
          context: ErrorDescription(
            'while canceling pending medication notifications',
          ),
        ),
      );
    }
  }

  Future<void> cancelMissedDoseNotification(String doseId) async {
    await _notificationGateway.cancel(missedNotificationIdForDose(doseId));
    await _pendingNotificationStore.removeByDoseId(doseId);
  }

  Future<void> dismissNotifications(String doseId) async {
    try {
      await _notificationGateway.cancel(primaryNotificationIdForDose(doseId));
      await _notificationGateway.cancel(missedNotificationIdForDose(doseId));
    } catch (error) {
      debugPrint('Failed to dismiss notifications for dose $doseId: $error');
    }
  }

  Future<void> syncPendingMissedNotifications() async {
    final pendingNotifications = await _pendingNotificationStore.loadPending();

    for (final notification in pendingNotifications) {
      final alreadyLogged = await _safeHasDoseLog(notification.dose.id);
      if (!alreadyLogged) {
        if (notification.scheduledTime.isBefore(DateTime.now())) {
          await _safeCreateMissedDoseAlert(notification.dose);
        }
        continue;
      }

      try {
        await _notificationGateway.cancel(notification.notificationId);
        await _pendingNotificationStore.removeByDoseId(notification.dose.id);
      } catch (error) {
        debugPrint(
          'Failed to reconcile missed notification for dose ${notification.dose.id}: $error',
        );
      }
    }
  }

  static int primaryNotificationIdForDose(String doseId) =>
      _stableNotificationId(doseId, salt: 17);

  static int missedNotificationIdForDose(String doseId) =>
      _stableNotificationId(doseId, salt: 53);

  static String buildDoseLoggingRoute(
    ScheduledDose dose, {
    bool isOverdue = false,
  }) {
    final uri = Uri(
      path: '/log-dose/${dose.id}',
      queryParameters: {
        'status': isOverdue ? 'overdue' : 'scheduled',
        'medicationId': dose.medicationId,
        'medicationName': dose.medicationName,
        'dosage': dose.dosage,
        'scheduledTime': dose.scheduledTime.toIso8601String(),
      },
    );
    return uri.toString();
  }

  static int _stableNotificationId(String value, {required int salt}) {
    var hash = salt;
    for (final codeUnit in value.codeUnits) {
      hash = ((hash * 31) + codeUnit) & 0x7fffffff;
    }
    return hash;
  }

  Future<bool> _safeHasDoseLog(String doseId) async {
    try {
      return await _doseLogRepository.hasDoseLog(doseId);
    } catch (error) {
      debugPrint('Failed to read dose log state for $doseId: $error');
      return false;
    }
  }

  Future<void> _safeCreateMissedDoseAlert(ScheduledDose dose) async {
    try {
      await _emergencyAlertRepository?.createMissedDoseAlert(
        medicationName: dose.medicationName,
        dosage: dose.dosage,
        scheduledTime: dose.scheduledTime,
      );
    } catch (error) {
      debugPrint('Failed to create missed dose alert for ${dose.id}: $error');
    }
  }
}
