import 'package:clinic_go/ui/home/models/scheduled_dose.dart';

class DoseLogEntry {
  const DoseLogEntry({
    required this.medicationId,
    required this.scheduledTime,
    required this.loggedAt,
    required this.status,
  });

  final String medicationId;
  final DateTime scheduledTime;
  final DateTime loggedAt;
  final DoseLogStatus status;
}
