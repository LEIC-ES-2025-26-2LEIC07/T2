import 'package:flutter/material.dart';
import 'package:clinic_go/features/medication/models/medication_reminder.dart';

/// Domain model matching the [medications] Supabase table.
class Medication {
  const Medication({
    required this.id,
    required this.userId,
    required this.name,
    this.dosageAmount,
    this.dosageUnit,
    this.frequency,
    required this.color,
    this.startDate,
    this.endDate,
    this.notes,
    required this.createdAt,
    this.withFood = false,
    this.reminders,
  });

  final String id;
  final String userId;
  final String name;
  final int? dosageAmount;
  final String? dosageUnit;
  final String? frequency;

  String? get dosageDisplay =>
      dosageAmount != null ? '$dosageAmount${dosageUnit ?? ''}' : null;
  final Color color;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? notes;
  final DateTime createdAt;
  final bool withFood;

  /// Reminder rows joined from medication_reminders — present only when
  /// fetched with select('*, medication_reminders(*)').
  final List<MedicationReminder>? reminders;

  /// True when endDate is null (ongoing) or still in the future.
  bool get isActive => endDate == null || endDate!.isAfter(DateTime.now());

  factory Medication.fromJson(Map<String, dynamic> json) {
    List<MedicationReminder>? reminders;
    final raw = json['medication_reminders'];
    if (raw is List) {
      reminders = raw
          .cast<Map<String, dynamic>>()
          .map(MedicationReminder.fromJson)
          .toList();
    }

    return Medication(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      dosageAmount: json['dosage'] as int?,
      dosageUnit: json['dosage_unit']?.toString() ?? 'mg',
      frequency: json['frequency']?.toString(),
      color: colorFromHex(json['color']?.toString() ?? '#4E84E5'),
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'] as String)
          : null,
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String)
          : null,
      notes: json['notes']?.toString(),
      createdAt: DateTime.parse(json['created_at'] as String),
      withFood: json['with_food'] as bool? ?? false,
      reminders: reminders,
    );
  }

  /// Converts '#RRGGBB' to a Flutter [Color].
  static Color colorFromHex(String hex) {
    final cleaned = hex.replaceFirst('#', '');
    return Color(int.parse('FF$cleaned', radix: 16));
  }

  /// Converts a Flutter [Color] to '#RRGGBB'.
  static String colorToHex(Color color) {
    final argb = color.toARGB32();
    final r = (argb >> 16) & 0xFF;
    final g = (argb >> 8) & 0xFF;
    final b = argb & 0xFF;
    return '#'
        '${r.toRadixString(16).padLeft(2, '0')}'
        '${g.toRadixString(16).padLeft(2, '0')}'
        '${b.toRadixString(16).padLeft(2, '0')}';
  }
}
