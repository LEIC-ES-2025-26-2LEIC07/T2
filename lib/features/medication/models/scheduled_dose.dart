class ScheduledDose {
  const ScheduledDose({
    required this.id,
    required this.medicationId,
    required this.medicationName,
    required this.dosage,
    required this.scheduledTime,
  });

  final String id;
  final String medicationId;
  final String medicationName;
  final String dosage;
  final DateTime scheduledTime;

  Map<String, dynamic> toJson() => {
    'id': id,
    'medicationId': medicationId,
    'medicationName': medicationName,
    'dosage': dosage,
    'scheduledTime': scheduledTime.toIso8601String(),
  };

  factory ScheduledDose.fromJson(Map<String, dynamic> json) => ScheduledDose(
    id: json['id'] as String,
    medicationId: json['medicationId'] as String,
    medicationName: json['medicationName'] as String,
    dosage: json['dosage'] as String,
    scheduledTime: DateTime.parse(json['scheduledTime'] as String),
  );
}
