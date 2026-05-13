class SymptomLog {
  const SymptomLog({
    required this.id,
    required this.userId,
    required this.symptomType,
    required this.severity,
    required this.notes,
    required this.occurredAt,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String symptomType;
  final int severity;
  final String? notes;
  final DateTime occurredAt;
  final DateTime createdAt;

  String get symptomLabel {
    return symptomType
        .split('_')
        .map((segment) => '${segment[0].toUpperCase()}${segment.substring(1)}')
        .join(' ');
  }

  factory SymptomLog.fromJson(Map<String, dynamic> json) {
    return SymptomLog(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      symptomType: json['symptom_type'] as String,
      severity: json['severity'] as int,
      notes: json['notes'] as String?,
      occurredAt: DateTime.parse(json['occurred_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
