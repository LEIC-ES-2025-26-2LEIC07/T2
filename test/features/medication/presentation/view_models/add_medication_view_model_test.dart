import 'package:clinic_go/features/medication/data/medication_repository.dart';
import 'package:clinic_go/features/medication/models/medication.dart';
import 'package:clinic_go/features/medication/models/medication_reminder.dart';

import 'package:clinic_go/features/medication/presentation/view_models/add_medication_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ── Hand-rolled mock repositories ──────────────────────────────────

class _SuccessRepo implements MedicationRepository {
  bool addCalled = false;

  @override
  Future<SavedMedicationResult> addMedication(
    AddMedicationPayload payload,
  ) async {
    addCalled = true;
    return const SavedMedicationResult(
      medicationId: 'new-id-123',
      reminders: [],
    );
  }

  @override
  Future<void> editMedication(EditMedicationPayload payload) async {}

  @override
  Future<List<Medication>> fetchMedications() async => [];

  @override
  Future<void> deleteMedication(String id) async {}

  @override
  Future<List<MedicationReminder>> fetchAllReminders() async => [];

  @override
  Future<List<MedicationReminder>> fetchRemindersForMedication(
    String medicationId,
  ) async => [];
}

class _RollbackRepo implements MedicationRepository {
  @override
  Future<SavedMedicationResult> addMedication(AddMedicationPayload _) async =>
      throw const MedicationSaveException(
        'Reminders could not be saved and the medication was rolled back.',
      );

  @override
  Future<void> editMedication(EditMedicationPayload payload) async {}

  @override
  Future<List<Medication>> fetchMedications() async => [];

  @override
  Future<void> deleteMedication(String id) async {}

  @override
  Future<List<MedicationReminder>> fetchAllReminders() async => [];

  @override
  Future<List<MedicationReminder>> fetchRemindersForMedication(
    String medicationId,
  ) async => [];
}

class _NetworkErrorRepo implements MedicationRepository {
  @override
  Future<SavedMedicationResult> addMedication(AddMedicationPayload _) async =>
      throw Exception('No internet');

  @override
  Future<void> editMedication(EditMedicationPayload payload) async {}

  @override
  Future<List<Medication>> fetchMedications() async =>
      throw Exception('No internet');

  @override
  Future<void> deleteMedication(String id) async {}

  @override
  Future<List<MedicationReminder>> fetchAllReminders() async => [];

  @override
  Future<List<MedicationReminder>> fetchRemindersForMedication(
    String medicationId,
  ) async => [];
}

// ── Tests ───────────────────────────────────────────────────────────

void main() {
  AddMedicationViewModel vmFactory({MedicationRepository? repo}) =>
      AddMedicationViewModel(repository: repo ?? _SuccessRepo());

  group('AddMedicationViewModel – validation', () {
    test('submit with empty name sets nameError', () async {
      final vm = vmFactory();
      vm.setDosageAmount(10);
      await vm.submit();

      expect(vm.nameError, isNotNull);
      expect(vm.isSuccess, isFalse);
      expect(vm.isLoading, isFalse);
    });

    test('submit with empty dosage sets dosageError', () async {
      final vm = vmFactory();
      vm.setName('Lisinopril');
      await vm.submit();

      expect(vm.dosageError, isNotNull);
      expect(vm.isSuccess, isFalse);
    });

    test('submit with both blank fields sets both errors', () async {
      final vm = vmFactory();
      await vm.submit();

      expect(vm.nameError, isNotNull);
      expect(vm.dosageError, isNotNull);
    });

    test('setName clears nameError', () async {
      final vm = vmFactory();
      await vm.submit(); // triggers nameError
      expect(vm.nameError, isNotNull);
      vm.setName('Aspirin');
      expect(vm.nameError, isNull);
    });
  });

  group('AddMedicationViewModel – happy path', () {
    test('sets isSuccess after successful submit', () async {
      final repo = _SuccessRepo();
      final vm = vmFactory(repo: repo);
      vm.setName('Lisinopril');
      vm.setDosageAmount(10);
      await vm.submit();

      expect(vm.isSuccess, isTrue);
      expect(vm.errorMessage, isNull);
      expect(repo.addCalled, isTrue);
    });

    test('isDirty becomes false after successful submit', () async {
      final vm = vmFactory();
      vm.setName('Med');
      vm.setDosageAmount(5);
      expect(vm.isDirty, isTrue);
      await vm.submit();
      expect(vm.isDirty, isFalse);
    });

    test('payload contains selected colour', () async {
      AddMedicationPayload? captured;
      final repo = _CapturingRepo((p) => captured = p);
      final vm = vmFactory(repo: repo);
      vm.setName('Med');
      vm.setDosageAmount(5);
      vm.setColor(const Color(0xFFE53935));
      await vm.submit();

      expect(captured?.color, equals(const Color(0xFFE53935)));
    });
  });

  group('AddMedicationViewModel – rollback path', () {
    test('sets errorMessage when MedicationSaveException is thrown', () async {
      final vm = vmFactory(repo: _RollbackRepo());
      vm.setName('Med');
      vm.setDosageAmount(5);
      await vm.submit();

      expect(vm.isSuccess, isFalse);
      expect(vm.errorMessage, contains('rolled back'));
    });

    test('sets generic errorMessage on unknown exception', () async {
      final vm = vmFactory(repo: _NetworkErrorRepo());
      vm.setName('Med');
      vm.setDosageAmount(5);
      await vm.submit();

      expect(vm.errorMessage, isNotNull);
      expect(vm.isSuccess, isFalse);
    });
  });

  group('AddMedicationViewModel – colour picker', () {
    test('setColor updates selectedColor', () {
      final vm = vmFactory();
      vm.setColor(const Color(0xFFE53935));
      expect(vm.selectedColor, equals(const Color(0xFFE53935)));
    });

    test('setColor marks form as dirty', () {
      final vm = vmFactory();
      expect(vm.isDirty, isFalse);
      vm.setColor(const Color(0xFF43A047));
      expect(vm.isDirty, isTrue);
    });
  });

  group('AddMedicationViewModel – reminder slots', () {
    test('Duas vezes por dia produces two reminder slots', () {
      final vm = vmFactory();
      vm.setFrequency('Duas vezes por dia');
      expect(vm.reminderTimes.length, 2);
    });

    test('Três vezes por dia produces three slots', () {
      final vm = vmFactory();
      vm.setFrequency('Três vezes por dia');
      expect(vm.reminderTimes.length, 3);
    });

    test('switching back to Uma vez por dia reduces to one slot', () {
      final vm = vmFactory();
      vm.setFrequency('Três vezes por dia');
      vm.setFrequency('Uma vez por dia');
      expect(vm.reminderTimes.length, 1);
    });
  });
}

// Helper capturing repo
class _CapturingRepo implements MedicationRepository {
  _CapturingRepo(this.onAdd);
  final void Function(AddMedicationPayload) onAdd;

  @override
  Future<SavedMedicationResult> addMedication(AddMedicationPayload p) async {
    onAdd(p);
    return const SavedMedicationResult(medicationId: 'id', reminders: []);
  }

  @override
  Future<void> editMedication(EditMedicationPayload payload) async {}

  @override
  Future<List<Medication>> fetchMedications() async => [];

  @override
  Future<void> deleteMedication(String id) async {}

  @override
  Future<List<MedicationReminder>> fetchAllReminders() async => [];

  @override
  Future<List<MedicationReminder>> fetchRemindersForMedication(
    String medicationId,
  ) async => [];
}
