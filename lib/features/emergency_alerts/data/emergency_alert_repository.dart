import '../models/emergency_alert.dart';

abstract class EmergencyAlertRepository {
  Future<List<EmergencyAlert>> fetchUnacknowledgedAlerts();

  Future<EmergencyAlert?> fetchAlert(String id);

  Future<void> acknowledgeAlert(String id);

  Stream<EmergencyAlert> watchInsertedAlerts();

  Future<void> syncPushToken(String token, String platform);

  Future<void> removePushToken(String token);

  Future<void> createMissedDoseAlert({
    required String medicationName,
    required String dosage,
    required DateTime scheduledTime,
    String? doseId,
  });
}
