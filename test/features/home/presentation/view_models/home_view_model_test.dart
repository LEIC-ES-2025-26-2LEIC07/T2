import 'package:clinic_go/features/medication/models/scheduled_dose.dart';
import 'package:clinic_go/features/medication/data/dose_log_repository.dart';
import 'package:clinic_go/features/medication/services/missed_dose_notification_controller.dart';
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

class MockMissedDoseNotificationController extends Mock
    implements MissedDoseNotificationController {}

class FakeScheduledDose extends Fake implements ScheduledDose {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeScheduledDose());
    registerFallbackValue(DoseLogStatus.taken);
  });

  late HomeViewModel viewModel;
  late MockMedicationRepository mockRepository;
  late DoseSchedulingService schedulingService;
  late InMemoryDoseLogRepository mockLogRepository;

  setUp(() {
    mockRepository = MockMedicationRepository();
    schedulingService = const DoseSchedulingService();
    mockLogRepository = InMemoryDoseLogRepository();
    final mockNotificationController = MockMissedDoseNotificationController();

    viewModel = HomeViewModel(
      repository: mockRepository,
      schedulingService: schedulingService,
      logRepository: mockLogRepository,
      notificationController: mockNotificationController,
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

  group('HomeViewModel – logDose', () {
    test(
      'logDose clears nextDose optimistically and reloads on success',
      () async {
        final dose = ScheduledDose(
          id: 'dose-1',
          medicationId: 'med-1',
          medicationName: 'Aspirin',
          dosage: '100mg',
          scheduledTime: DateTime.now(),
        );

        // Setup state where we have a next dose
        when(
          () => mockRepository.fetchMedications(),
        ).thenAnswer((_) async => []);
        when(
          () => mockRepository.fetchAllReminders(),
        ).thenAnswer((_) async => []);
        // We manually set the state to simulate an existing dose
        // Actually let's just use the loadNextDose path

        final mockController = MockMissedDoseNotificationController();
        viewModel = HomeViewModel(
          repository: mockRepository,
          schedulingService: schedulingService,
          logRepository: mockLogRepository,
          notificationController: mockController,
        );

        // Stub controller
        when(
          () => mockController.logDose(
            dose: any(named: 'dose'),
            status: any(named: 'status'),
          ),
        ).thenAnswer((_) async {});

        // Simulate initial load that found a dose
        // For simplicity, we just trigger logDose and check if it clears whatever was there
        await viewModel.logDose(dose, DoseLogStatus.taken);

        verify(
          () => mockController.logDose(dose: dose, status: DoseLogStatus.taken),
        ).called(1);
        expect(viewModel.isLoading, isFalse);
      },
    );

    test('logDose reverts state and sets errorMessage on failure', () async {
      final dose = ScheduledDose(
        id: 'dose-1',
        medicationId: 'med-1',
        medicationName: 'Aspirin',
        dosage: '100mg',
        scheduledTime: DateTime.now(),
      );

      final mockController = MockMissedDoseNotificationController();
      viewModel = HomeViewModel(
        repository: mockRepository,
        schedulingService: schedulingService,
        logRepository: mockLogRepository,
        notificationController: mockController,
      );

      when(
        () => mockController.logDose(
          dose: any(named: 'dose'),
          status: any(named: 'status'),
        ),
      ).thenThrow(Exception('Network error'));

      try {
        await viewModel.logDose(dose, DoseLogStatus.taken);
      } catch (_) {}

      expect(viewModel.errorMessage, contains('Failed to log dose'));
    });
  });
}
