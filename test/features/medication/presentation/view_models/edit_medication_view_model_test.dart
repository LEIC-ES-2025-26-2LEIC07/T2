import 'package:clinic_go/features/medication/data/medication_repository.dart';
import 'package:clinic_go/features/medication/models/medication.dart';
import 'package:clinic_go/features/medication/models/medication_reminder.dart';
import 'package:clinic_go/features/medication/presentation/view_models/edit_medication_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ── Fixtures ──────────────────────────────────────────────────────────────────

Medication _med({
  String id = 'med-1',
  String name = 'Metformina',
  int dosageAmount = 500,
  String frequency = 'Uma vez por dia',
}) => Medication(
  id: id,
  userId: 'u1',
  name: name,
  dosageAmount: dosageAmount,
  dosageUnit: 'mg',
  frequency: frequency,
  color: Colors.blue,
  createdAt: DateTime(2026, 1, 1),
);

MedicationReminder _reminder() => MedicationReminder(
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
);

// ── Repositories ──────────────────────────────────────────────────────────────

class _SuccessRepo implements MedicationRepository {
  final List<MedicationReminder> reminders;
  bool editCalled = false;

  _SuccessRepo({this.reminders = const []});

  @override
  Future<SavedMedicationResult> addMedication(AddMedicationPayload p) async =>
      const SavedMedicationResult(medicationId: 'id', reminders: []);

  @override
  Future<void> editMedication(EditMedicationPayload payload) async {
    editCalled = true;
  }

  @override
  Future<List<Medication>> fetchMedications() async => [];

  @override
  Future<void> deleteMedication(String id) async {}

  @override
  Future<List<MedicationReminder>> fetchAllReminders() async => [];

  @override
  Future<List<MedicationReminder>> fetchRemindersForMedication(
    String medicationId,
  ) async => reminders;
}

class _FailEditRepo extends _SuccessRepo {
  @override
  Future<void> editMedication(EditMedicationPayload payload) async =>
      throw Exception('Server error');

  @override
  Future<List<MedicationReminder>> fetchRemindersForMedication(
    String medicationId,
  ) async => throw Exception('Reminders error');
}

class _FailDeleteRepo extends _SuccessRepo {
  @override
  Future<void> deleteMedication(String id) async =>
      throw Exception('Delete failed');
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('EditMedicationViewModel – initial state', () {
    test('pre-fills all fields from the medication object', () {
      final vm = EditMedicationViewModel(
        repository: _SuccessRepo(),
        medication: _med(),
      );

      expect(vm.name, 'Metformina');
      expect(vm.dosageAmount, 500);
      expect(vm.dosageUnit, 'mg');
      expect(vm.frequency, 'interval:1');
      expect(vm.isSuccess, false);
      expect(vm.isDirty, false);
      expect(vm.errorMessage, isNull);

      vm.dispose();
    });
  });

  group('EditMedicationViewModel – loadReminders', () {
    test('populates slots from repository', () async {
      final repo = _SuccessRepo(reminders: [_reminder()]);
      final vm = EditMedicationViewModel(repository: repo, medication: _med());

      await vm.loadReminders();

      expect(vm.reminderSlots.length, 1);
      expect(vm.reminderSlots.first.id, 'rem-1');
      expect(vm.reminderSlots.first.time.hour, 8);
      expect(vm.isLoadingReminders, false);

      vm.dispose();
    });

    test(
      'falls back to single 08:00 slot when repository returns empty',
      () async {
        final vm = EditMedicationViewModel(
          repository: _SuccessRepo(),
          medication: _med(),
        );

        await vm.loadReminders();

        expect(vm.reminderSlots.length, 1);
        expect(vm.reminderSlots.first.time.hour, 8);
        expect(vm.reminderSlots.first.id, isNull);
        expect(vm.isLoadingReminders, false);

        vm.dispose();
      },
    );

    test('falls back to single slot when repository throws', () async {
      final vm = EditMedicationViewModel(
        repository: _FailEditRepo(),
        medication: _med(),
      );

      await vm.loadReminders();

      expect(vm.reminderSlots.length, 1);
      expect(vm.isLoadingReminders, false);

      vm.dispose();
    });
  });

  group('EditMedicationViewModel – validation', () {
    test('submit with blank name sets nameError and returns early', () async {
      final vm = EditMedicationViewModel(
        repository: _SuccessRepo(),
        medication: _med(name: ''),
      );
      await vm.loadReminders();

      await vm.submit();

      expect(vm.nameError, isNotNull);
      expect(vm.isSuccess, false);

      vm.dispose();
    });

    test(
      'submit with null dosage sets dosageError and returns early',
      () async {
        final vm = EditMedicationViewModel(
          repository: _SuccessRepo(),
          medication: _med(),
        );
        await vm.loadReminders();
        vm.setDosageAmount(null);

        await vm.submit();

        expect(vm.dosageError, isNotNull);
        expect(vm.isSuccess, false);

        vm.dispose();
      },
    );

    test('submit with both blank sets both errors', () async {
      final vm = EditMedicationViewModel(
        repository: _SuccessRepo(),
        medication: _med(name: ''),
      );
      await vm.loadReminders();
      vm.setDosageAmount(null);

      await vm.submit();

      expect(vm.nameError, isNotNull);
      expect(vm.dosageError, isNotNull);

      vm.dispose();
    });
  });

  group('EditMedicationViewModel – happy path submit', () {
    test('sets isSuccess and clears isDirty after successful save', () async {
      final repo = _SuccessRepo();
      final vm = EditMedicationViewModel(repository: repo, medication: _med());
      await vm.loadReminders();

      await vm.submit();

      expect(vm.isSuccess, true);
      expect(vm.isDirty, false);
      expect(vm.errorMessage, isNull);
      expect(vm.isLoading, false);
      expect(repo.editCalled, true);

      vm.dispose();
    });
  });

  group('EditMedicationViewModel – submit failure', () {
    test('sets errorMessage when repo throws, isSuccess stays false', () async {
      final vm = EditMedicationViewModel(
        repository: _FailEditRepo(),
        medication: _med(),
      );
      await vm.loadReminders();

      await vm.submit();

      expect(vm.isSuccess, false);
      expect(vm.errorMessage, isNotNull);
      expect(vm.isLoading, false);

      vm.dispose();
    });
  });

  group('EditMedicationViewModel – deleteMedication', () {
    test('sets wasDeleted and isSuccess on success', () async {
      final vm = EditMedicationViewModel(
        repository: _SuccessRepo(),
        medication: _med(),
      );

      await vm.deleteMedication();

      expect(vm.wasDeleted, true);
      expect(vm.isSuccess, true);
      expect(vm.errorMessage, isNull);

      vm.dispose();
    });

    test('sets errorMessage and keeps wasDeleted false on failure', () async {
      final vm = EditMedicationViewModel(
        repository: _FailDeleteRepo(),
        medication: _med(),
      );

      await vm.deleteMedication();

      expect(vm.wasDeleted, false);
      expect(vm.isSuccess, false);
      expect(vm.errorMessage, isNotNull);

      vm.dispose();
    });
  });
}
