import 'package:clinic_go/features/medication/models/medication.dart';
import 'package:clinic_go/features/medication/models/medication_reminder.dart';
import 'package:clinic_go/features/medication/services/dose_scheduling_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late DoseSchedulingService service;
  late Medication med;

  setUp(() {
    service = const DoseSchedulingService();
    med = Medication(
      id: 'med-1',
      userId: 'user-1',
      name: 'Lisinopril',
      dosage: '10mg',
      color: Colors.blue,
      createdAt: DateTime(2026, 4, 1),
    );
  });

  group('DoseSchedulingService – calculateUpcomingDoses', () {
    test(
      'calculateUpcomingDoses: [Happy path] → returns correctly scheduled doses',
      () {
        final now = DateTime(2026, 4, 20, 10, 0); // 10:00 AM
        final reminders = [
          MedicationReminder(
            id: 'rem-1',
            medicationId: 'med-1',
            reminderTime: '08:00:00',
            daysOfWeek: const [
              'monday',
              'tuesday',
              'wednesday',
              'thursday',
              'friday',
              'saturday',
              'sunday',
            ],
          ),
          MedicationReminder(
            id: 'rem-2',
            medicationId: 'med-1',
            reminderTime: '20:00:00',
            daysOfWeek: const [
              'monday',
              'tuesday',
              'wednesday',
              'thursday',
              'friday',
              'saturday',
              'sunday',
            ],
          ),
        ];

        final results = service.calculateUpcomingDoses(
          med,
          reminders,
          from: now,
          duration: const Duration(hours: 24),
        );

        // Should find: Today 20:00, Tomorrow 08:00
        expect(results.length, 2);
        expect(results[0].scheduledTime, DateTime(2026, 4, 20, 20, 0));
        expect(results[1].scheduledTime, DateTime(2026, 4, 21, 8, 0));
        expect(results[0].id, contains('rem-2_'));
      },
    );

    test(
      'calculateUpcomingDoses: [Lookback] → finds overdue doses in the past',
      () {
        final now = DateTime(2026, 4, 20, 10, 0); // 10:00 AM
        final reminders = [
          MedicationReminder(
            id: 'rem-1',
            medicationId: 'med-1',
            reminderTime: '08:00:00',
            daysOfWeek: const [
              'monday',
              'tuesday',
              'wednesday',
              'thursday',
              'friday',
              'saturday',
              'sunday',
            ],
          ),
        ];

        final results = service.calculateUpcomingDoses(
          med,
          reminders,
          from: now.subtract(const Duration(hours: 3)), // from 07:00 AM
          duration: const Duration(hours: 4), // until 11:00 AM
        );

        // Should find: 08:00 AM (which is in the past relative to 'now')
        expect(results.length, 1);
        expect(results[0].scheduledTime, DateTime(2026, 4, 20, 8, 0));
      },
    );

    test(
      'calculateUpcomingDoses: [Empty result] → returns empty list if no reminders',
      () {
        final now = DateTime.now();
        final results = service.calculateUpcomingDoses(
          med,
          [],
          from: now,
          duration: const Duration(hours: 24),
        );

        expect(results, isEmpty);
      },
    );

    test(
      'calculateUpcomingDoses: [Boundaries] → respects duration limit exactly',
      () {
        final now = DateTime(2026, 4, 20, 8, 0);
        final reminders = [
          MedicationReminder(
            id: 'rem-1',
            medicationId: 'med-1',
            reminderTime: '12:00:00',
            daysOfWeek: const [
              'monday',
              'tuesday',
              'wednesday',
              'thursday',
              'friday',
              'saturday',
              'sunday',
            ],
          ),
        ];

        final results = service.calculateUpcomingDoses(
          med,
          reminders,
          from: now,
          duration: const Duration(hours: 3), // until 11:00 AM
        );

        // 12:00 is outside the 3-hour window
        expect(results, isEmpty);
      },
    );
  });
}
