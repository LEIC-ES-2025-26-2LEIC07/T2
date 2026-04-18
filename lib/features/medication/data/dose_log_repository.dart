import '../models/scheduled_dose.dart';

enum DoseLogStatus { taken, skipped }

abstract class DoseLogRepository {
  Future<void> insertDoseLog({
    required ScheduledDose dose,
    required DoseLogStatus status,
    required DateTime loggedAt,
  });

  Future<bool> hasDoseLog(String doseId);
}
