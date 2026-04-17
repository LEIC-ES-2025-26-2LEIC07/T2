enum DoseLogStatus { pending, taken, skipped }

class ScheduledDose {
  const ScheduledDose({
    required this.medicationId,
    required this.medicationName,
    required this.dosage,
    required this.scheduledTime,
    this.status = DoseLogStatus.pending,
    this.loggedAt,
    this.isSyncing = false,
  });

  final String medicationId;
  final String medicationName;
  final String dosage;
  final DateTime scheduledTime;
  final DoseLogStatus status;
  final DateTime? loggedAt;
  final bool isSyncing;

  bool get isCompleted => status != DoseLogStatus.pending;

  ScheduledDose copyWith({
    String? medicationId,
    String? medicationName,
    String? dosage,
    DateTime? scheduledTime,
    DoseLogStatus? status,
    DateTime? loggedAt,
    bool clearLoggedAt = false,
    bool? isSyncing,
  }) {
    return ScheduledDose(
      medicationId: medicationId ?? this.medicationId,
      medicationName: medicationName ?? this.medicationName,
      dosage: dosage ?? this.dosage,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      status: status ?? this.status,
      loggedAt: clearLoggedAt ? null : loggedAt ?? this.loggedAt,
      isSyncing: isSyncing ?? this.isSyncing,
    );
  }
}
