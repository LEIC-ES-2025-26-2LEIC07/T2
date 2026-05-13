import 'package:clinic_go/features/symptoms/models/symptom_log.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const validJson = <String, dynamic>{
    'id': 'log-1',
    'user_id': 'user-1',
    'symptom_id': 'symptom-1',
    'custom_symptom': null,
    'symptoms': {'name': 'headache'},
    'severity': 5,
    'notes': 'Mild headache after waking up',
    'occurred_at': '2026-05-13T08:00:00.000Z',
    'created_at': '2026-05-13T08:05:00.000Z',
  };

  group('SymptomLog.fromJson', () {
    test('parses all fields correctly', () {
      final log = SymptomLog.fromJson(validJson);

      expect(log.id, 'log-1');
      expect(log.userId, 'user-1');
      expect(log.symptomType, 'headache');
      expect(log.severity, 5);
      expect(log.notes, 'Mild headache after waking up');
      expect(log.occurredAt, DateTime.parse('2026-05-13T08:00:00.000Z'));
      expect(log.createdAt, DateTime.parse('2026-05-13T08:05:00.000Z'));
    });

    test('accepts null notes', () {
      final json = Map<String, dynamic>.from(validJson)..['notes'] = null;
      final log = SymptomLog.fromJson(json);
      expect(log.notes, isNull);
    });

    test('uses custom_symptom when there is no linked symptom', () {
      final json = Map<String, dynamic>.from(validJson)
        ..['symptoms'] = null
        ..['custom_symptom'] = 'itchy eyes';
      final log = SymptomLog.fromJson(json);
      expect(log.symptomType, 'itchy eyes');
      expect(log.symptomLabel, 'Itchy Eyes');
    });

    test('throws TypeError when required field id is missing', () {
      final json = Map<String, dynamic>.from(validJson)..remove('id');
      expect(() => SymptomLog.fromJson(json), throwsA(isA<TypeError>()));
    });

    test('throws when occurred_at is not a valid date string', () {
      final json = Map<String, dynamic>.from(validJson)
        ..['occurred_at'] = 'not-a-date';
      expect(() => SymptomLog.fromJson(json), throwsA(anything));
    });

    test('throws when severity is not an int', () {
      final json = Map<String, dynamic>.from(validJson)..['severity'] = 'high';
      expect(() => SymptomLog.fromJson(json), throwsA(isA<TypeError>()));
    });
  });

  group('SymptomLog.symptomLabel', () {
    SymptomLog logFor(String symptomType) => SymptomLog(
      id: '1',
      userId: 'u1',
      symptomType: symptomType,
      severity: 3,
      notes: null,
      occurredAt: DateTime(2026),
      createdAt: DateTime(2026),
    );

    test('single word: capitalises first letter', () {
      expect(logFor('headache').symptomLabel, 'Headache');
    });

    test('two-segment type converts to title case with space', () {
      expect(logFor('brain_fog').symptomLabel, 'Brain Fog');
    });

    test('three-segment type converts all segments', () {
      expect(logFor('shortness_of_breath').symptomLabel, 'Shortness Of Breath');
    });

    test('muscle_pain converts to Muscle Pain', () {
      expect(logFor('muscle_pain').symptomLabel, 'Muscle Pain');
    });
  });
}
