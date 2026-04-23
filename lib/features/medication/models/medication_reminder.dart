/// Domain model matching the [medication_reminders] Supabase table.
class MedicationReminder {
  const MedicationReminder({
    this.id,
    required this.medicationId,
    required this.reminderTime,
    required this.daysOfWeek,
    this.isActive = true,
  });

  final String? id;
  final String medicationId;

  /// Postgres TIME value formatted as 'HH:mm:ss', e.g. '08:00:00'.
  final String reminderTime;

  /// Postgres TEXT[] — day names, e.g. ['monday', 'friday'].
  final List<String> daysOfWeek;

  final bool isActive;

  Map<String, dynamic> toInsertJson() => {
    'medication_id': medicationId,
    'reminder_time': reminderTime,
    'days_of_week': daysOfWeek,
    'is_active': isActive,
  };

  factory MedicationReminder.fromJson(Map<String, dynamic> json) =>
      MedicationReminder(
        id: json['id']?.toString(),
        medicationId: json['medication_id'] as String,
        reminderTime: json['reminder_time'] as String,
        daysOfWeek: (json['days_of_week'] as List<dynamic>).cast<String>(),
        isActive: json['is_active'] as bool? ?? true,
      );
}
