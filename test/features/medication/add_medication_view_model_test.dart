import 'package:clinic_go/features/medication/data/medication_repository.dart';
import 'package:clinic_go/features/medication/models/medication.dart';
import 'package:clinic_go/features/medication/presentation/view_models/add_medication_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ── Hand-rolled mock repositories ──────────────────────────────────

class _SuccessRepo implements MedicationRepository {
  bool addCalled = false;

  @override
  Future<String> addMedication(AddMedicationPayload payload) async {
    addCalled = true;
    return 'new-id-123';
  }

  @override
  Future<List<Medication>> fetchMedications() async => [];

  @override
  Future<void> deleteMedication(String id) async {}
}

class _RollbackRepo implements MedicationRepository {
  @override
  Future<String> addMedication(AddMedicationPayload _) async =>
      throw const MedicationSaveException(
        'Reminders could not be saved and the medication was rolled back.',
      );

  @override
  Future<List<Medication>> fetchMedications() async => [];

  @override
  Future<void> deleteMedication(String id) async {}
}

class _NetworkErrorRepo implements MedicationRepository {
  @override
  Future<String> addMedication(AddMedicationPayload _) async =>
      throw Exception('No internet');

  @override
  Future<List<Medication>> fetchMedications() async =>
      throw Exception('No internet');

  @override
  Future<void> deleteMedication(String id) async {}
}

// ── Tests ───────────────────────────────────────────────────────────

void main() {
  group('AddMedicationViewModel – validation', () {
    test('submit with empty name sets nameError', () async {
      final vm = AddMedicationViewModel(repository: _SuccessRepo());
      vm.setDosage('10mg');
      await vm.submit();

      expect(vm.nameError, isNotNull);
      expect(vm.isSuccess, isFalse);
      expect(vm.isLoading, isFalse);
    });

    test('submit with empty dosage sets dosageError', () async {
      final vm = AddMedicationViewModel(repository: _SuccessRepo());
      vm.setName('Lisinopril');
      await vm.submit();

      expect(vm.dosageError, isNotNull);
      expect(vm.isSuccess, isFalse);
    });

    test('submit with both blank fields sets both errors', () async {
      final vm = AddMedicationViewModel(repository: _SuccessRepo());
      await vm.submit();

      expect(vm.nameError, isNotNull);
      expect(vm.dosageError, isNotNull);
    });

    test('setName clears nameError', () async {
      final vm = AddMedicationViewModel(repository: _SuccessRepo());
      await vm.submit(); // triggers nameError
      expect(vm.nameError, isNotNull);
      vm.setName('Aspirin');
      expect(vm.nameError, isNull);
    });
  });

  group('AddMedicationViewModel – happy path', () {
    test('sets isSuccess after successful submit', () async {
      final repo = _SuccessRepo();
      final vm = AddMedicationViewModel(repository: repo);
      vm.setName('Lisinopril');
      vm.setDosage('10 mg');
      await vm.submit();

      expect(vm.isSuccess, isTrue);
      expect(vm.errorMessage, isNull);
      expect(repo.addCalled, isTrue);
    });

    test('isDirty becomes false after successful submit', () async {
      final vm = AddMedicationViewModel(repository: _SuccessRepo());
      vm.setName('Med');
      vm.setDosage('5mg');
      expect(vm.isDirty, isTrue);
      await vm.submit();
      expect(vm.isDirty, isFalse);
    });

    test('payload contains selected colour', () async {
      AddMedicationPayload? captured;
      final repo = _CapturingRepo((p) => captured = p);
      final vm = AddMedicationViewModel(repository: repo);
      vm.setName('Med');
      vm.setDosage('5mg');
      vm.setColor(const Color(0xFFE53935));
      await vm.submit();

      expect(captured?.color, equals(const Color(0xFFE53935)));
    });
  });

  group('AddMedicationViewModel – rollback path', () {
    test('sets errorMessage when MedicationSaveException is thrown', () async {
      final vm = AddMedicationViewModel(repository: _RollbackRepo());
      vm.setName('Med');
      vm.setDosage('5mg');
      await vm.submit();

      expect(vm.isSuccess, isFalse);
      expect(vm.errorMessage, contains('rolled back'));
    });

    test('sets generic errorMessage on unknown exception', () async {
      final vm = AddMedicationViewModel(repository: _NetworkErrorRepo());
      vm.setName('Med');
      vm.setDosage('5mg');
      await vm.submit();

      expect(vm.errorMessage, isNotNull);
      expect(vm.isSuccess, isFalse);
    });
  });

  group('AddMedicationViewModel – colour picker', () {
    test('setColor updates selectedColor', () {
      final vm = AddMedicationViewModel(repository: _SuccessRepo());
      vm.setColor(const Color(0xFFE53935));
      expect(vm.selectedColor, equals(const Color(0xFFE53935)));
    });

    test('setColor marks form as dirty', () {
      final vm = AddMedicationViewModel(repository: _SuccessRepo());
      expect(vm.isDirty, isFalse);
      vm.setColor(const Color(0xFF43A047));
      expect(vm.isDirty, isTrue);
    });
  });

  group('AddMedicationViewModel – reminder slots', () {
    test('Twice daily produces two reminder slots', () {
      final vm = AddMedicationViewModel(repository: _SuccessRepo());
      vm.setFrequency('Twice daily');
      expect(vm.reminderTimes.length, 2);
    });

    test('Three times daily produces three slots', () {
      final vm = AddMedicationViewModel(repository: _SuccessRepo());
      vm.setFrequency('Three times daily');
      expect(vm.reminderTimes.length, 3);
    });

    test('switching back to Once daily reduces to one slot', () {
      final vm = AddMedicationViewModel(repository: _SuccessRepo());
      vm.setFrequency('Three times daily');
      vm.setFrequency('Once daily');
      expect(vm.reminderTimes.length, 1);
    });
  });
}

// Helper capturing repo
class _CapturingRepo implements MedicationRepository {
  _CapturingRepo(this.onAdd);
  final void Function(AddMedicationPayload) onAdd;

  @override
  Future<String> addMedication(AddMedicationPayload p) async {
    onAdd(p);
    return 'id';
  }

  @override
  Future<List<Medication>> fetchMedications() async => [];

  @override
  Future<void> deleteMedication(String id) async {}
}
