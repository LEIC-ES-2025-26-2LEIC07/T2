import 'package:clinic_go/features/home/presentation/view_models/home_view_model.dart';
import 'package:clinic_go/features/medication/data/medication_repository.dart';
import 'package:clinic_go/features/medication/models/medication.dart';
import 'package:clinic_go/features/medication/models/medication_reminder.dart';
import 'package:clinic_go/features/medication/services/dose_scheduling_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:intl/intl.dart';
import '../../../../helpers/medication_mocks.dart';

class MockMedicationRepository extends Mock implements MedicationRepository {}

void main() {
  late HomeViewModel viewModel;
  late MockMedicationRepository mockRepository;
  late DoseSchedulingService schedulingService;
  late InMemoryDoseLogRepository mockLogRepository;

  setUp(() {
    mockRepository = MockMedicationRepository();
    schedulingService = const DoseSchedulingService();
    mockLogRepository = InMemoryDoseLogRepository();

    viewModel = HomeViewModel(
      repository: mockRepository,
      schedulingService: schedulingService,
      logRepository: mockLogRepository,
    );
  });

  group('HomeViewModel – loadNextDose', () {
    test(
      'loadNextDose: [Loading state] → sets isLoading correctly during fetch',
      () async {
        when(() => mockRepository.fetchMedications()).thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 50));
          return [];
        });
        when(
          () => mockRepository.fetchAllReminders(),
        ).thenAnswer((_) async => []);

        final future = viewModel.loadNextDose();
        expect(viewModel.isLoading, isTrue);

        await future;
        expect(viewModel.isLoading, isFalse);
      },
    );

    test(
      'loadNextDose: [Success state] → identifies the next upcoming dose',
      () async {
        final upcomingTime = DateTime.now().add(const Duration(minutes: 30));
        final upcomingStr = DateFormat('HH:mm:ss').format(upcomingTime);

        final med = Medication(
          id: 'med-1',
          userId: 'u1',
          name: 'Aspirin',
          dosage: '100mg',
          color: Colors.red,
          createdAt: DateTime(2026, 1, 1),
        );

        final reminders = [
          MedicationReminder(
            id: 'rem-1',
            medicationId: 'med-1',
            reminderTime: upcomingStr,
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

        when(
          () => mockRepository.fetchMedications(),
        ).thenAnswer((_) async => [med]);
        when(
          () => mockRepository.fetchAllReminders(),
        ).thenAnswer((_) async => reminders);

        await viewModel.loadNextDose();

        expect(viewModel.nextDose, isNotNull);
        expect(viewModel.nextDose!.medicationName, 'Aspirin');
        expect(viewModel.isOverdue, isFalse);
      },
    );

    test(
      'loadNextDose: [Overdue state] → identifies an overdue dose',
      () async {
        final overdueTime = DateTime.now().subtract(
          const Duration(minutes: 30),
        );
        final overdueStr = DateFormat('HH:mm:ss').format(overdueTime);

        final med = Medication(
          id: 'med-1',
          userId: 'u1',
          name: 'Aspirin',
          dosage: '100mg',
          color: Colors.red,
          createdAt: DateTime(2026, 1, 1),
        );

        final reminders = [
          MedicationReminder(
            id: 'rem-1',
            medicationId: 'med-1',
            reminderTime: overdueStr,
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

        when(
          () => mockRepository.fetchMedications(),
        ).thenAnswer((_) async => [med]);
        when(
          () => mockRepository.fetchAllReminders(),
        ).thenAnswer((_) async => reminders);

        await viewModel.loadNextDose();

        expect(viewModel.nextDose, isNotNull);
        expect(viewModel.isOverdue, isTrue);
      },
    );

    test(
      'loadNextDose: [Empty result] → handles case with no medications safely',
      () async {
        when(
          () => mockRepository.fetchMedications(),
        ).thenAnswer((_) async => []);
        when(
          () => mockRepository.fetchAllReminders(),
        ).thenAnswer((_) async => []);

        await viewModel.loadNextDose();

        expect(viewModel.nextDose, isNull);
        expect(viewModel.isLoading, isFalse);
      },
    );

    test('loadNextDose: [Empty result] → ignores doses already logged', () async {
      // Use a mid-day time to avoid date-wraps during test execution
      final baseDate = DateTime.now();
      final reminderStr = '12:00:00';

      final med = Medication(
        id: 'stable-med-id',
        userId: 'u1',
        name: 'Aspirin',
        dosage: '100mg',
        color: Colors.red,
        createdAt: baseDate.subtract(const Duration(days: 10)),
      );

      final reminders = [
        MedicationReminder(
          id: 'stable-rem-id',
          medicationId: 'stable-med-id',
          reminderTime: reminderStr,
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

      when(
        () => mockRepository.fetchMedications(),
      ).thenAnswer((_) async => [med]);
      when(
        () => mockRepository.fetchAllReminders(),
      ).thenAnswer((_) async => reminders);

      // Seed doses for several days around 'now' to be bulletproof against any internal clock drift
      for (int i = -2; i <= 2; i++) {
        final d = DateTime(
          baseDate.year,
          baseDate.month,
          baseDate.day,
          12,
          0,
          0,
        ).add(Duration(days: i));
        final timestamp = d.millisecondsSinceEpoch ~/ 1000;
        final doseId = '${med.id}_$timestamp';
        mockLogRepository.seedLoggedDose(doseId);
      }

      await viewModel.loadNextDose();

      expect(viewModel.nextDose, isNull);
    });
  });
}
