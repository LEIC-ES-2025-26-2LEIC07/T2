class MonthlyMedicationLog {
  const MonthlyMedicationLog({
    required this.id,
    required this.takenAt,
    required this.wasTaken,
    required this.medicationName,
    required this.dosage,
  });

  final String id;
  final DateTime takenAt;
  final bool wasTaken;
  final String medicationName;
  final String dosage;

  factory MonthlyMedicationLog.fromJson(Map<String, dynamic> json) {
    final reminder = _asMap(json['medication_reminders']);
    final medication = _asMap(reminder['medications']);

    return MonthlyMedicationLog(
      id: json['id'] as String,
      takenAt: DateTime.parse(json['taken_at'] as String).toLocal(),
      wasTaken: json['was_taken'] as bool? ?? false,
      medicationName: medication['name'] as String? ?? 'Medicação',
      dosage: medication['dosage'] as String? ?? '',
    );
  }

  static Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return const <String, dynamic>{};
  }
}
