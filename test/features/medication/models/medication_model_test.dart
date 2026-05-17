import 'package:clinic_go/features/medication/models/medication.dart';
import 'package:clinic_go/features/medication/models/medication_reminder.dart';
import 'package:clinic_go/features/medication/models/scheduled_dose.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _baseJson({
  String id = 'med-1',
  String userId = 'user-1',
  String name = 'Metformina',
  int? dosage = 500,
  String dosageUnit = 'mg',
  String color = '#E53935',
  String createdAt = '2025-01-01T00:00:00.000Z',
}) => {
  'id': id,
  'user_id': userId,
  'name': name,
  'dosage': dosage,
  'dosage_unit': dosageUnit,
  'frequency': 'Once daily',
  'color': color,
  'start_date': null,
  'end_date': null,
  'notes': null,
  'created_at': createdAt,
  'with_food': false,
};

void main() {
  group('Medication.fromJson', () {
    test('parses all required fields correctly', () {
      final med = Medication.fromJson(_baseJson());

      expect(med.id, 'med-1');
      expect(med.userId, 'user-1');
      expect(med.name, 'Metformina');
      expect(med.dosageAmount, 500);
      expect(med.dosageUnit, 'mg');
      expect(med.frequency, 'Once daily');
      expect(med.withFood, isFalse);
    });

    test('parses color hex to Flutter Color', () {
      final med = Medication.fromJson(_baseJson(color: '#E53935'));
      expect(med.color, const Color(0xFFE53935));
    });

    test('falls back to default color when color is null', () {
      final json = _baseJson();
      json['color'] = null;
      final med = Medication.fromJson(json);
      expect(med.color, const Color(0xFF4E84E5));
    });

    test('accepts null dosage and leaves dosageAmount null', () {
      final med = Medication.fromJson(_baseJson(dosage: null));
      expect(med.dosageAmount, isNull);
    });

    test('defaults dosageUnit to "mg" when dosage_unit is null', () {
      final json = _baseJson();
      json['dosage_unit'] = null;
      final med = Medication.fromJson(json);
      expect(med.dosageUnit, 'mg');
    });

    test('parses nested medication_reminders list', () {
      final json = _baseJson();
      json['medication_reminders'] = [
        {
          'id': 'rem-1',
          'medication_id': 'med-1',
          'reminder_time': '08:00:00',
          'days_of_week': ['monday', 'friday'],
          'is_active': true,
        },
      ];

      final med = Medication.fromJson(json);
      expect(med.reminders, hasLength(1));
      expect(med.reminders!.first.id, 'rem-1');
    });

    test('reminders is null when key is absent', () {
      final med = Medication.fromJson(_baseJson());
      expect(med.reminders, isNull);
    });

    test('parses start_date and end_date', () {
      final json = _baseJson();
      json['start_date'] = '2025-01-01';
      json['end_date'] = '2025-12-31';
      final med = Medication.fromJson(json);
      expect(med.startDate, DateTime.parse('2025-01-01'));
      expect(med.endDate, DateTime.parse('2025-12-31'));
    });
  });

  group('Medication.dosageDisplay', () {
    test('returns "500mg" when amount=500 and unit="mg"', () {
      final med = Medication.fromJson(_baseJson(dosage: 500, dosageUnit: 'mg'));
      expect(med.dosageDisplay, '500mg');
    });

    test('appends unit correctly for different units', () {
      final json = _baseJson(dosage: 10, dosageUnit: 'ml');
      final med = Medication.fromJson(json);
      expect(med.dosageDisplay, '10ml');
    });

    test('returns null when dosageAmount is null', () {
      final med = Medication.fromJson(_baseJson(dosage: null));
      expect(med.dosageDisplay, isNull);
    });
  });

  group('Medication.isActive', () {
    test('is true when endDate is null (ongoing)', () {
      final med = Medication.fromJson(_baseJson());
      expect(med.isActive, isTrue);
    });

    test('is true when endDate is in the future', () {
      final json = _baseJson();
      json['end_date'] = DateTime.now()
          .add(const Duration(days: 30))
          .toIso8601String();
      final med = Medication.fromJson(json);
      expect(med.isActive, isTrue);
    });

    test('is false when endDate is in the past', () {
      final json = _baseJson();
      json['end_date'] = '2020-01-01T00:00:00.000Z';
      final med = Medication.fromJson(json);
      expect(med.isActive, isFalse);
    });
  });

  group('Medication.colorFromHex / colorToHex', () {
    test('colorFromHex parses #RRGGBB correctly', () {
      expect(Medication.colorFromHex('#E53935'), const Color(0xFFE53935));
      expect(Medication.colorFromHex('#000000'), const Color(0xFF000000));
      expect(Medication.colorFromHex('#FFFFFF'), const Color(0xFFFFFFFF));
    });

    test('colorToHex formats Color to #RRGGBB', () {
      expect(Medication.colorToHex(const Color(0xFFE53935)), '#e53935');
    });

    test('colorFromHex and colorToHex round-trip', () {
      const original = Color(0xFF3D6BE0);
      final hex = Medication.colorToHex(original);
      expect(Medication.colorFromHex(hex), original);
    });
  });

  group('MedicationReminder.fromJson', () {
    test('parses all fields', () {
      final reminder = MedicationReminder.fromJson({
        'id': 'rem-1',
        'medication_id': 'med-1',
        'reminder_time': '09:30:00',
        'days_of_week': ['monday', 'wednesday', 'friday'],
        'is_active': true,
      });

      expect(reminder.id, 'rem-1');
      expect(reminder.medicationId, 'med-1');
      expect(reminder.reminderTime, '09:30:00');
      expect(reminder.daysOfWeek, ['monday', 'wednesday', 'friday']);
      expect(reminder.isActive, isTrue);
    });

    test('defaults isActive to true when absent', () {
      final reminder = MedicationReminder.fromJson({
        'id': 'rem-2',
        'medication_id': 'med-1',
        'reminder_time': '08:00:00',
        'days_of_week': <String>[],
      });
      expect(reminder.isActive, isTrue);
    });

    test('toInsertJson produces expected keys', () {
      const reminder = MedicationReminder(
        medicationId: 'med-1',
        reminderTime: '08:00:00',
        daysOfWeek: ['monday'],
      );

      final json = reminder.toInsertJson();

      expect(json['medication_id'], 'med-1');
      expect(json['reminder_time'], '08:00:00');
      expect(json['days_of_week'], ['monday']);
      expect(json['is_active'], isTrue);
      expect(json.containsKey('id'), isFalse);
    });
  });

  group('ScheduledDose serialisation', () {
    final dose = ScheduledDose(
      id: 'rem-1_1746000000',
      medicationId: 'med-1',
      medicationName: 'Metformina',
      dosage: '500mg',
      scheduledTime: DateTime.utc(2025, 5, 1, 8, 0),
    );

    test('toJson produces expected map', () {
      final json = dose.toJson();
      expect(json['id'], 'rem-1_1746000000');
      expect(json['medicationId'], 'med-1');
      expect(json['medicationName'], 'Metformina');
      expect(json['dosage'], '500mg');
      expect(json['scheduledTime'], '2025-05-01T08:00:00.000Z');
    });

    test('fromJson round-trips toJson', () {
      final decoded = ScheduledDose.fromJson(dose.toJson());
      expect(decoded.id, dose.id);
      expect(decoded.medicationId, dose.medicationId);
      expect(decoded.medicationName, dose.medicationName);
      expect(decoded.dosage, dose.dosage);
      expect(decoded.scheduledTime, dose.scheduledTime);
    });
  });
}
