enum DoseStatus { pending, taken, skipped }

class ScheduledDose {
  const ScheduledDose({
    required this.id,
    required this.medicationId,
    required this.medicationName,
    required this.dosage,
    required this.instructions,
    required this.scheduledTime,
    this.status = DoseStatus.pending,
    this.loggedAt,
  });

  final String id;
  final String medicationId;
  final String medicationName;
  final String dosage;
  final String instructions;
  final DateTime scheduledTime;
  final DoseStatus status;
  final DateTime? loggedAt;

  bool get isCompleted => status != DoseStatus.pending;

  ScheduledDose copyWith({
    String? id,
    String? medicationId,
    String? medicationName,
    String? dosage,
    String? instructions,
    DateTime? scheduledTime,
    DoseStatus? status,
    DateTime? loggedAt,
    bool clearLoggedAt = false,
  }) {
    return ScheduledDose(
      id: id ?? this.id,
      medicationId: medicationId ?? this.medicationId,
      medicationName: medicationName ?? this.medicationName,
      dosage: dosage ?? this.dosage,
      instructions: instructions ?? this.instructions,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      status: status ?? this.status,
      loggedAt: clearLoggedAt ? null : (loggedAt ?? this.loggedAt),
    );
  }
}
