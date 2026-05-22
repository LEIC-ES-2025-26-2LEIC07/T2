import 'package:clinic_go/features/calendar/data/calendar_repository.dart';
import 'package:clinic_go/features/emergency_alerts/data/emergency_alert_repository.dart';
import 'package:clinic_go/features/emergency_alerts/models/emergency_alert.dart';
import 'package:clinic_go/features/medication/data/dose_log_repository.dart';
import 'package:clinic_go/features/medication/models/scheduled_dose.dart';
import 'package:clinic_go/features/medication/services/local_notification_gateway.dart';

// ---------------------------------------------------------------------------
// Shared in-memory mocks for medication & notification tests.
// ---------------------------------------------------------------------------

class MemoryNotificationGateway implements LocalNotificationGateway {
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

  @override
  Future<bool> requestPermissions() async => true;

  @override
  Future<bool> hasPermissions() async => true;
}

class InMemoryDoseLogRepository implements DoseLogRepository {
  final Set<String> loggedDoseIds = <String>{};

  @override
  Future<bool> hasDoseLog(String doseId) async =>
      loggedDoseIds.contains(doseId);

  @override
  Future<void> insertDoseLog({
    required ScheduledDose dose,
    required DoseLogStatus status,
    required DateTime loggedAt,
  }) async {
    loggedDoseIds.add(dose.id);
  }

  /// Convenience helper: pre-seed a logged dose for sync tests.
  void seedLoggedDose(String doseId) => loggedDoseIds.add(doseId);
}

class EmptyCalendarRepository implements CalendarRepository {
  @override
  Future<List<DoseLogEntry>> fetchDoseLogs({
    required DateTime from,
    required DateTime to,
  }) async => [];
}

class FailingDoseLogRepository implements DoseLogRepository {
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

class CapturingEmergencyAlertRepository implements EmergencyAlertRepository {
  final List<Map<String, dynamic>> createdAlerts = [];

  @override
  Future<void> createMissedDoseAlert({
    required String medicationName,
    required String dosage,
    required DateTime scheduledTime,
    String? doseId,
  }) async {
    createdAlerts.add({
      'medicationName': medicationName,
      'dosage': dosage,
      'scheduledTime': scheduledTime,
      'doseId': doseId,
    });
  }

  @override
  Future<List<EmergencyAlert>> fetchUnacknowledgedAlerts() async => [];

  @override
  Future<EmergencyAlert?> fetchAlert(String id) async => null;

  @override
  Future<void> acknowledgeAlert(String id) async {}

  @override
  Stream<EmergencyAlert> watchInsertedAlerts() => const Stream.empty();

  @override
  Future<void> syncPushToken(String token, String platform) async {}

  @override
  Future<void> removePushToken(String token) async {}
}
