import 'package:clinic_go/features/medication/data/medication_repository.dart';
import 'package:clinic_go/features/medication/models/medication.dart';
import 'package:clinic_go/features/medication/models/medication_reminder.dart';
import 'package:clinic_go/features/medication/presentation/view_models/add_medication_view_model.dart';
import 'package:clinic_go/features/medication/services/missed_dose_notification_controller.dart';
import 'package:clinic_go/features/medication/services/dose_scheduling_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockMissedDoseNotificationController extends Mock
    implements MissedDoseNotificationController {}

class MockDoseSchedulingService extends Mock implements DoseSchedulingService {}

class FakeMedication extends Fake implements Medication {}

class FakeMedicationReminder extends Fake implements MedicationReminder {}

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
  Future<List<Medication>> fetchMedications() async => [];

  @override
  Future<void> deleteMedication(String id) async {}

  @override
  Future<List<MedicationReminder>> fetchAllReminders() async => [];
}

class _RollbackRepo implements MedicationRepository {
  @override
  Future<SavedMedicationResult> addMedication(AddMedicationPayload _) async =>
      throw const MedicationSaveException(
        'Reminders could not be saved and the medication was rolled back.',
      );

  @override
  Future<List<Medication>> fetchMedications() async => [];

  @override
  Future<void> deleteMedication(String id) async {}

  @override
  Future<List<MedicationReminder>> fetchAllReminders() async => [];
}

class _NetworkErrorRepo implements MedicationRepository {
  @override
  Future<SavedMedicationResult> addMedication(AddMedicationPayload _) async =>
      throw Exception('No internet');

  @override
  Future<List<Medication>> fetchMedications() async =>
      throw Exception('No internet');

  @override
  Future<void> deleteMedication(String id) async {}

  @override
  Future<List<MedicationReminder>> fetchAllReminders() async => [];
}

// ── Tests ───────────────────────────────────────────────────────────

void main() {
  setUpAll(() {
    registerFallbackValue(FakeMedication());
    registerFallbackValue(FakeMedicationReminder());
    registerFallbackValue(
      Medication(
        id: '',
        userId: '',
        name: '',
        color: Colors.black,
        createdAt: DateTime(2000),
      ),
    );
    registerFallbackValue(<MedicationReminder>[]);
  });

  late MockMissedDoseNotificationController mockController;
  late MockDoseSchedulingService mockScheduling;

  setUp(() {
    mockController = MockMissedDoseNotificationController();
    mockScheduling = MockDoseSchedulingService();

    // Stubbing for the happy-path logic
    when(
      () => mockScheduling.calculateUpcomingDoses(any(), any()),
    ).thenReturn([]);
  });

  AddMedicationViewModel vmFactory({MedicationRepository? repo}) =>
      AddMedicationViewModel(
        repository: repo ?? _SuccessRepo(),
        notificationController: mockController,
        schedulingService: mockScheduling,
      );

  group('AddMedicationViewModel – validation', () {
    test('submit with empty name sets nameError', () async {
      final vm = vmFactory();
      vm.setDosage('10mg');
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
      vm.setDosage('10 mg');
      await vm.submit();

      expect(vm.isSuccess, isTrue);
      expect(vm.errorMessage, isNull);
      expect(repo.addCalled, isTrue);
    });

    test('isDirty becomes false after successful submit', () async {
      final vm = vmFactory();
      vm.setName('Med');
      vm.setDosage('5mg');
      expect(vm.isDirty, isTrue);
      await vm.submit();
      expect(vm.isDirty, isFalse);
    });

    test('payload contains selected colour', () async {
      AddMedicationPayload? captured;
      final repo = _CapturingRepo((p) => captured = p);
      final vm = vmFactory(repo: repo);
      vm.setName('Med');
      vm.setDosage('5mg');
      vm.setColor(const Color(0xFFE53935));
      await vm.submit();

      expect(captured?.color, equals(const Color(0xFFE53935)));
    });
  });

  group('AddMedicationViewModel – rollback path', () {
    test('sets errorMessage when MedicationSaveException is thrown', () async {
      final vm = vmFactory(repo: _RollbackRepo());
      vm.setName('Med');
      vm.setDosage('5mg');
      await vm.submit();

      expect(vm.isSuccess, isFalse);
      expect(vm.errorMessage, contains('rolled back'));
    });

    test('sets generic errorMessage on unknown exception', () async {
      final vm = vmFactory(repo: _NetworkErrorRepo());
      vm.setName('Med');
      vm.setDosage('5mg');
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
    test('Twice daily produces two reminder slots', () {
      final vm = vmFactory();
      vm.setFrequency('Twice daily');
      expect(vm.reminderTimes.length, 2);
    });

    test('Three times daily produces three slots', () {
      final vm = vmFactory();
      vm.setFrequency('Three times daily');
      expect(vm.reminderTimes.length, 3);
    });

    test('switching back to Once daily reduces to one slot', () {
      final vm = vmFactory();
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
  Future<SavedMedicationResult> addMedication(AddMedicationPayload p) async {
    onAdd(p);
    return const SavedMedicationResult(medicationId: 'id', reminders: []);
  }

  @override
  Future<List<Medication>> fetchMedications() async => [];

  @override
  Future<void> deleteMedication(String id) async {}

  @override
  Future<List<MedicationReminder>> fetchAllReminders() async => [];
}
