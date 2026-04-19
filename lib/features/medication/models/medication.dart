import 'package:flutter/material.dart';

/// Domain model matching the [medications] Supabase table.
class Medication {
  const Medication({
    required this.id,
    required this.userId,
    required this.name,
    this.dosage,
    this.frequency,
    required this.color,
    this.startDate,
    this.endDate,
    this.notes,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String name;
  final String? dosage;
  final String? frequency;
  final Color color;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? notes;
  final DateTime createdAt;

  factory Medication.fromJson(Map<String, dynamic> json) => Medication(
    id: json['id'] as String,
    userId: json['user_id'] as String,
    name: json['name'] as String,
    dosage: json['dosage'] as String?,
    frequency: json['frequency'] as String?,
    color: colorFromHex(json['color'] as String? ?? '#4E84E5'),
    startDate: json['start_date'] != null
        ? DateTime.parse(json['start_date'] as String)
        : null,
    endDate: json['end_date'] != null
        ? DateTime.parse(json['end_date'] as String)
        : null,
    notes: json['notes'] as String?,
    createdAt: DateTime.parse(json['created_at'] as String),
  );

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
