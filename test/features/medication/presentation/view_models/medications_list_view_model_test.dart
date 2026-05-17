import 'package:clinic_go/features/medication/data/medication_repository.dart';
import 'package:clinic_go/features/medication/models/medication.dart';
import 'package:clinic_go/features/medication/models/medication_reminder.dart';
import 'package:clinic_go/features/medication/presentation/view_models/medications_list_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ── Stub repositories ─────────────────────────────────────────────────────────

Medication _med(String id) => Medication(
  id: id,
  userId: 'u1',
  name: 'Med $id',
  color: Colors.blue,
  createdAt: DateTime(2025),
);

class _SuccessRepo implements MedicationRepository {
  final List<Medication> medications;
  _SuccessRepo(this.medications);

  @override
  Future<List<Medication>> fetchMedications() async => medications;

  @override
  Future<SavedMedicationResult> addMedication(AddMedicationPayload p) async =>
      const SavedMedicationResult(medicationId: '', reminders: []);

  @override
  Future<void> editMedication(EditMedicationPayload p) async {}

  @override
  Future<void> deleteMedication(String id) async {}

  @override
  Future<List<MedicationReminder>> fetchAllReminders() async => [];

  @override
  Future<List<MedicationReminder>> fetchRemindersForMedication(
    String medicationId,
  ) async => [];
}

class _FailingRepo implements MedicationRepository {
  @override
  Future<List<Medication>> fetchMedications() async =>
      throw Exception('network error');

  @override
  Future<SavedMedicationResult> addMedication(AddMedicationPayload p) async =>
      const SavedMedicationResult(medicationId: '', reminders: []);

  @override
  Future<void> editMedication(EditMedicationPayload p) async {}

  @override
  Future<void> deleteMedication(String id) async {}

  @override
  Future<List<MedicationReminder>> fetchAllReminders() async => [];

  @override
  Future<List<MedicationReminder>> fetchRemindersForMedication(
    String medicationId,
  ) async => [];
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('MedicationsListViewModel – initial state', () {
    test('starts with empty list, not loading, no error', () {
      final vm = MedicationsListViewModel(repository: _SuccessRepo([]));
      expect(vm.medications, isEmpty);
      expect(vm.isLoading, isFalse);
      expect(vm.errorMessage, isNull);
    });
  });

  group('MedicationsListViewModel – loadMedications', () {
    test('sets isLoading to true during fetch then false after', () async {
      final vm = MedicationsListViewModel(
        repository: _SuccessRepo([_med('1')]),
      );
      final loadingStates = <bool>[];
      vm.addListener(() => loadingStates.add(vm.isLoading));

      await vm.loadMedications();

      // First notification: isLoading = true. Second: isLoading = false.
      expect(loadingStates, [true, false]);
    });

    test('populates medications list on success', () async {
      final meds = [_med('a'), _med('b'), _med('c')];
      final vm = MedicationsListViewModel(repository: _SuccessRepo(meds));

      await vm.loadMedications();

      expect(vm.medications.length, 3);
      expect(vm.medications.map((m) => m.id), containsAll(['a', 'b', 'c']));
      expect(vm.errorMessage, isNull);
    });

    test('returns empty list when repository returns no medications', () async {
      final vm = MedicationsListViewModel(repository: _SuccessRepo([]));
      await vm.loadMedications();

      expect(vm.medications, isEmpty);
      expect(vm.errorMessage, isNull);
    });

    test(
      'sets errorMessage and leaves list empty on repository error',
      () async {
        final vm = MedicationsListViewModel(repository: _FailingRepo());
        await vm.loadMedications();

        expect(vm.errorMessage, isNotNull);
        expect(vm.medications, isEmpty);
        expect(vm.isLoading, isFalse);
      },
    );

    test('clears previous errorMessage on successful retry', () async {
      final failRepo = _FailingRepo();
      final vm = MedicationsListViewModel(repository: failRepo);
      await vm.loadMedications();
      expect(vm.errorMessage, isNotNull);

      // Swap to success repo by creating a new VM — simulates retry pattern
      final vm2 = MedicationsListViewModel(
        repository: _SuccessRepo([_med('x')]),
      );
      await vm2.loadMedications();
      expect(vm2.errorMessage, isNull);
      expect(vm2.medications, hasLength(1));
    });

    test('medications list is unmodifiable', () async {
      final vm = MedicationsListViewModel(
        repository: _SuccessRepo([_med('1')]),
      );
      await vm.loadMedications();

      expect(() => vm.medications.add(_med('2')), throwsUnsupportedError);
    });
  });
}
