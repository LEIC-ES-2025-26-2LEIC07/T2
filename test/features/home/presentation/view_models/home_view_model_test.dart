import 'package:clinic_go/features/home/presentation/view_models/home_view_model.dart';
import 'package:clinic_go/features/medication/data/dose_log_repository.dart';
import 'package:clinic_go/features/medication/data/medication_repository.dart';
import 'package:clinic_go/features/medication/models/medication.dart';
import 'package:clinic_go/features/medication/models/medication_reminder.dart';
import 'package:clinic_go/features/medication/models/scheduled_dose.dart';
import 'package:clinic_go/features/medication/services/dose_scheduling_service.dart';
import 'package:clinic_go/features/medication/services/missed_dose_notification_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:intl/intl.dart';
import '../../../../helpers/medication_mocks.dart';

class MockMedicationRepository extends Mock implements MedicationRepository {}

class MockMissedDoseNotificationController extends Mock
    implements MissedDoseNotificationController {}

void main() {
  late HomeViewModel viewModel;
  late MockMedicationRepository mockRepository;
  late DoseSchedulingService schedulingService;
  late InMemoryDoseLogRepository mockLogRepository;

  setUpAll(() {
    registerFallbackValue(
      ScheduledDose(
        id: '',
        medicationId: '',
        medicationName: '',
        dosage: '',
        scheduledTime: DateTime(2000),
      ),
    );
    registerFallbackValue(DoseLogStatus.taken);
  });

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
          dosageAmount: 100,
          dosageUnit: 'mg',
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
          dosageAmount: 100,
          dosageUnit: 'mg',
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

    test(
      'nextDose is null when today doses are all logged even if tomorrow has doses',
      () async {
        // Verifies that tomorrow's pending dose does not suppress "all done today".
        final now = DateTime.now();
        const reminderId = 'rem-tomorrow-test';

        final med = Medication(
          id: 'med-1',
          userId: 'u1',
          name: 'Aspirin',
          dosageAmount: 100,
          dosageUnit: 'mg',
          color: Colors.red,
          createdAt: DateTime(2026, 1, 1),
        );
        final reminders = [
          MedicationReminder(
            id: reminderId,
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

        when(
          () => mockRepository.fetchMedications(),
        ).thenAnswer((_) async => [med]);
        when(
          () => mockRepository.fetchAllReminders(),
        ).thenAnswer((_) async => reminders);

        // Seed today's noon dose as logged.
        final todayNoon = DateTime(now.year, now.month, now.day, 12);
        final timestamp = todayNoon.millisecondsSinceEpoch ~/ 1000;
        mockLogRepository.seedLoggedDose('${reminderId}_$timestamp');

        await viewModel.loadNextDose();

        // Before fix: nextDose pointed to tomorrow's noon dose (bug).
        // After fix:  nextDose is null — "all done for today" state.
        expect(viewModel.nextDose, isNull);
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
        dosageAmount: 100,
        dosageUnit: 'mg',
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
        final doseId = '${reminders.first.id}_$timestamp';
        mockLogRepository.seedLoggedDose(doseId);
      }

      await viewModel.loadNextDose();

      expect(viewModel.nextDose, isNull);
    });
  });

  group('HomeViewModel – loadNextDose error handling', () {
    test(
      'loadNextDose when repository throws → clears state and isLoading false',
      () async {
        when(
          () => mockRepository.fetchMedications(),
        ).thenThrow(StateError('db error'));

        await viewModel.loadNextDose();

        expect(viewModel.nextDose, isNull);
        expect(viewModel.isLoading, isFalse);
        expect(viewModel.todayDoses.isEmpty, isTrue);
      },
    );
  });

  group('HomeViewModel – logDose', () {
    final dose = ScheduledDose(
      id: 'test-dose',
      medicationId: 'm1',
      medicationName: 'Aspirin',
      dosage: '100mg',
      scheduledTime: DateTime.now().add(const Duration(minutes: 30)),
    );

    test('logDose success (no notificationController) → inserts log', () async {
      when(() => mockRepository.fetchMedications()).thenAnswer((_) async => []);
      when(
        () => mockRepository.fetchAllReminders(),
      ).thenAnswer((_) async => []);

      await viewModel.logDose(dose: dose, status: DoseLogStatus.taken);

      expect(viewModel.isLoggingDose, isFalse);
      expect(mockLogRepository.loggedDoseIds.contains(dose.id), isTrue);
    });

    test('logDose error path → restores state and rethrows', () async {
      final failRepo = FailingDoseLogRepository();
      final upcomingTime = DateTime.now().add(const Duration(minutes: 30));
      final upcomingStr = DateFormat('HH:mm:ss').format(upcomingTime);

      final med = Medication(
        id: 'med-1',
        userId: 'u1',
        name: 'Aspirin',
        dosageAmount: 100,
        dosageUnit: 'mg',
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

      final vm = HomeViewModel(
        repository: mockRepository,
        schedulingService: schedulingService,
        logRepository: failRepo,
      );

      await vm.loadNextDose();
      final prevDose = vm.nextDose;
      expect(prevDose, isNotNull);

      await expectLater(
        vm.logDose(dose: dose, status: DoseLogStatus.taken),
        throwsA(isA<StateError>()),
      );

      expect(vm.isLoggingDose, isFalse);
      expect(vm.nextDose, equals(prevDose));
    });

    test('logDose delegates to notificationController when provided', () async {
      final mockController = MockMissedDoseNotificationController();
      when(
        () => mockController.logDose(
          dose: any(named: 'dose'),
          status: any(named: 'status'),
          loggedAt: any(named: 'loggedAt'),
        ),
      ).thenAnswer((_) async {});
      when(() => mockRepository.fetchMedications()).thenAnswer((_) async => []);
      when(
        () => mockRepository.fetchAllReminders(),
      ).thenAnswer((_) async => []);

      final vm = HomeViewModel(
        repository: mockRepository,
        schedulingService: schedulingService,
        logRepository: mockLogRepository,
        notificationController: mockController,
      );

      await vm.logDose(dose: dose, status: DoseLogStatus.taken);

      verify(
        () => mockController.logDose(
          dose: any(named: 'dose'),
          status: any(named: 'status'),
          loggedAt: any(named: 'loggedAt'),
        ),
      ).called(1);
    });
  });

  group('HomeViewModel – doseLogged', () {
    test('doseLogged clears nextDose and isOverdue', () async {
      final overdueTime = DateTime.now().subtract(const Duration(minutes: 30));
      final overdueStr = DateFormat('HH:mm:ss').format(overdueTime);

      final med = Medication(
        id: 'med-1',
        userId: 'u1',
        name: 'Aspirin',
        dosageAmount: 100,
        dosageUnit: 'mg',
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

      viewModel.doseLogged();

      expect(viewModel.nextDose, isNull);
      expect(viewModel.isOverdue, isFalse);
    });
  });
}
