import 'package:clinic_go/features/medication/data/dose_log_repository.dart';
import 'package:clinic_go/features/medication/data/medication_repository.dart';
import 'package:clinic_go/features/medication/models/medication.dart';
import 'package:clinic_go/features/medication/models/medication_reminder.dart';
import 'package:clinic_go/features/medication/models/scheduled_dose.dart';
import 'package:clinic_go/features/medication/presentation/view_models/daily_doses_view_model.dart';
import 'package:clinic_go/features/medication/services/dose_scheduling_service.dart';
import 'package:clinic_go/features/medication/services/missed_dose_notification_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/medication_mocks.dart';

// ── Mocks ─────────────────────────────────────────────────────────────────────

class MockDoseSchedulingService extends Mock implements DoseSchedulingService {}

class MockMissedDoseNotificationController extends Mock
    implements MissedDoseNotificationController {}

class FakeMedication extends Fake implements Medication {}

class FakeMedicationReminder extends Fake implements MedicationReminder {}

class FakeScheduledDose extends Fake implements ScheduledDose {}

// ── Stub repositories ─────────────────────────────────────────────────────────

Medication _med({String id = 'med-1'}) => Medication(
  id: id,
  userId: 'u1',
  name: 'Aspirin',
  dosageAmount: 100,
  dosageUnit: 'mg',
  color: Colors.blue,
  createdAt: DateTime(2025),
);

MedicationReminder _reminder({String medicationId = 'med-1'}) =>
    MedicationReminder(
      id: 'rem-1',
      medicationId: medicationId,
      reminderTime: '08:00:00',
      daysOfWeek: ['monday', 'tuesday', 'wednesday', 'thursday', 'friday'],
    );

ScheduledDose _dose({String id = 'dose-1'}) => ScheduledDose(
  id: id,
  medicationId: 'med-1',
  medicationName: 'Aspirin',
  dosage: '100mg',
  scheduledTime: DateTime.now().add(const Duration(hours: 1)),
);

class _StubMedRepo implements MedicationRepository {
  final List<Medication> meds;
  final List<MedicationReminder> reminders;
  final bool shouldThrow;

  const _StubMedRepo({
    this.meds = const [],
    this.reminders = const [],
    this.shouldThrow = false,
  });

  @override
  Future<List<Medication>> fetchMedications() async {
    if (shouldThrow) throw Exception('network failure');
    return meds;
  }

  @override
  Future<List<MedicationReminder>> fetchAllReminders() async => reminders;

  @override
  Future<SavedMedicationResult> addMedication(AddMedicationPayload p) async =>
      const SavedMedicationResult(medicationId: '', reminders: []);

  @override
  Future<void> editMedication(EditMedicationPayload p) async {}

  @override
  Future<void> deleteMedication(String id) async {}

  @override
  Future<List<MedicationReminder>> fetchRemindersForMedication(
    String medicationId,
  ) async => [];
}

// ── Helper: build VM with mocked scheduling that returns a fixed dose ─────────

void _stubScheduling(
  MockDoseSchedulingService scheduling,
  List<ScheduledDose> returns,
) {
  when(
    () => scheduling.calculateUpcomingDoses(
      any(),
      any(),
      from: any(named: 'from'),
      duration: any(named: 'duration'),
    ),
  ).thenReturn(returns);
}

DailyDosesViewModel _vmWithDose({
  required MockDoseSchedulingService scheduling,
  required DoseLogRepository logRepo,
  required ScheduledDose dose,
  MissedDoseNotificationController? notificationController,
}) {
  _stubScheduling(scheduling, [dose]);

  return DailyDosesViewModel(
    repository: _StubMedRepo(meds: [_med()], reminders: [_reminder()]),
    schedulingService: scheduling,
    logRepository: logRepo,
    notificationController: notificationController,
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  setUpAll(() {
    registerFallbackValue(FakeMedication());
    registerFallbackValue(FakeMedicationReminder());
    registerFallbackValue(FakeScheduledDose());
    registerFallbackValue(DoseLogStatus.taken);
    registerFallbackValue(const Duration());
    registerFallbackValue(DateTime(2000));
  });

  group('DailyDosesViewModel – initial state', () {
    test('starts empty, not loading, no error', () {
      final vm = DailyDosesViewModel(
        repository: const _StubMedRepo(),
        schedulingService: MockDoseSchedulingService(),
        logRepository: InMemoryDoseLogRepository(),
      );
      expect(vm.doses, isEmpty);
      expect(vm.isLoading, isFalse);
      expect(vm.errorMessage, isNull);
    });
  });

  group('DailyDosesViewModel – loadTodayDoses', () {
    test('toggles isLoading true then false', () async {
      final scheduling = MockDoseSchedulingService();
      _stubScheduling(scheduling, []);

      final vm = DailyDosesViewModel(
        repository: const _StubMedRepo(meds: []),
        schedulingService: scheduling,
        logRepository: InMemoryDoseLogRepository(),
      );

      final states = <bool>[];
      vm.addListener(() => states.add(vm.isLoading));
      await vm.loadTodayDoses();

      expect(states.first, isTrue);
      expect(states.last, isFalse);
    });

    test('loads pending doses not yet logged', () async {
      final scheduling = MockDoseSchedulingService();
      final dose = _dose();
      final logRepo = InMemoryDoseLogRepository();

      final vm = _vmWithDose(
        scheduling: scheduling,
        logRepo: logRepo,
        dose: dose,
      );

      await vm.loadTodayDoses();

      expect(vm.doses, hasLength(1));
      expect(vm.doses.first.dose.id, 'dose-1');
      expect(vm.errorMessage, isNull);
    });

    test('excludes doses already logged', () async {
      final scheduling = MockDoseSchedulingService();
      final dose = _dose();
      final logRepo = InMemoryDoseLogRepository()..seedLoggedDose(dose.id);

      final vm = _vmWithDose(
        scheduling: scheduling,
        logRepo: logRepo,
        dose: dose,
      );

      await vm.loadTodayDoses();

      expect(vm.doses, isEmpty);
    });

    test('sets errorMessage and leaves doses empty on repo failure', () async {
      final scheduling = MockDoseSchedulingService();

      final vm = DailyDosesViewModel(
        repository: const _StubMedRepo(shouldThrow: true),
        schedulingService: scheduling,
        logRepository: InMemoryDoseLogRepository(),
      );

      await vm.loadTodayDoses();

      expect(vm.errorMessage, isNotNull);
      expect(vm.doses, isEmpty);
      expect(vm.isLoading, isFalse);
    });

    test('refresh calls loadTodayDoses', () async {
      final scheduling = MockDoseSchedulingService();
      _stubScheduling(scheduling, []);

      final vm = DailyDosesViewModel(
        repository: const _StubMedRepo(),
        schedulingService: scheduling,
        logRepository: InMemoryDoseLogRepository(),
      );

      await vm.refresh();

      expect(vm.isLoading, isFalse);
      expect(vm.errorMessage, isNull);
    });

    test('doses list is unmodifiable', () async {
      final scheduling = MockDoseSchedulingService();
      _stubScheduling(scheduling, []);

      final vm = DailyDosesViewModel(
        repository: const _StubMedRepo(),
        schedulingService: scheduling,
        logRepository: InMemoryDoseLogRepository(),
      );

      await vm.loadTodayDoses();

      expect(
        () => vm.doses.add(DoseItem(dose: _dose())),
        throwsUnsupportedError,
      );
    });
  });

  group('DailyDosesViewModel – logDose', () {
    test('throws StateError when dose is not in the loaded list', () async {
      final scheduling = MockDoseSchedulingService();
      _stubScheduling(scheduling, []);

      final vm = DailyDosesViewModel(
        repository: const _StubMedRepo(),
        schedulingService: scheduling,
        logRepository: InMemoryDoseLogRepository(),
      );

      await vm.loadTodayDoses();

      expect(
        () => vm.logDose(dose: _dose(), status: DoseLogStatus.taken),
        throwsStateError,
      );
    });

    test('marks dose as taken after successful log', () async {
      final scheduling = MockDoseSchedulingService();
      final dose = _dose();
      final logRepo = InMemoryDoseLogRepository();

      final vm = _vmWithDose(
        scheduling: scheduling,
        logRepo: logRepo,
        dose: dose,
      );

      await vm.loadTodayDoses();
      await vm.logDose(dose: dose, status: DoseLogStatus.taken);

      expect(vm.doses.first.status, DoseLogStatus.taken);
      expect(vm.doses.first.isSubmitting, isFalse);
    });

    test('marks dose as skipped after successful log', () async {
      final scheduling = MockDoseSchedulingService();
      final dose = _dose();
      final logRepo = InMemoryDoseLogRepository();

      final vm = _vmWithDose(
        scheduling: scheduling,
        logRepo: logRepo,
        dose: dose,
      );

      await vm.loadTodayDoses();
      await vm.logDose(dose: dose, status: DoseLogStatus.skipped);

      expect(vm.doses.first.status, DoseLogStatus.skipped);
    });

    test('rollback on log repository failure restores prior state', () async {
      final scheduling = MockDoseSchedulingService();
      final dose = _dose();
      final failRepo = FailingDoseLogRepository();

      final vm = _vmWithDose(
        scheduling: scheduling,
        logRepo: failRepo,
        dose: dose,
      );

      await vm.loadTodayDoses();

      await expectLater(
        () => vm.logDose(dose: dose, status: DoseLogStatus.taken),
        throwsA(isA<StateError>()),
      );

      // State rolled back
      expect(vm.doses.first.status, isNull);
      expect(vm.doses.first.isSubmitting, isFalse);
    });

    test('delegates to notificationController when provided', () async {
      final scheduling = MockDoseSchedulingService();
      final dose = _dose();
      final logRepo = InMemoryDoseLogRepository();
      final mockController = MockMissedDoseNotificationController();

      when(
        () => mockController.logDose(
          dose: any(named: 'dose'),
          status: any(named: 'status'),
          loggedAt: any(named: 'loggedAt'),
        ),
      ).thenAnswer((_) async {});

      final vm = _vmWithDose(
        scheduling: scheduling,
        logRepo: logRepo,
        dose: dose,
        notificationController: mockController,
      );

      await vm.loadTodayDoses();
      await vm.logDose(dose: dose, status: DoseLogStatus.taken);

      verify(
        () => mockController.logDose(
          dose: any(named: 'dose'),
          status: DoseLogStatus.taken,
          loggedAt: any(named: 'loggedAt'),
        ),
      ).called(1);
    });
  });
}
