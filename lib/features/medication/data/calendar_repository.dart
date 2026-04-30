import 'dose_log_repository.dart';

class DoseLogEntry {
  DoseLogEntry({
    required this.id,
    required this.status,
    required this.scheduledTime,
    this.takenTime,
    this.medicationId,
    this.medicationName,
    this.dosage,
  });

  final String id;
  final DoseLogStatus status;
  final DateTime scheduledTime;
  final DateTime? takenTime;
  final String? medicationId;
  final String? medicationName;
  final String? dosage;
}

abstract class CalendarRepository {
  /// Returns all logged dose entries whose scheduled_time falls within the
  /// provided range (inclusive).
  Future<List<DoseLogEntry>> fetchDoseLogs({
    required DateTime from,
    required DateTime to,
  });
}
