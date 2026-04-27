import 'package:clinic_go/core/color_palette/app_colors.dart';
import 'package:clinic_go/features/home/presentation/views/main_screen.dart';
import 'package:clinic_go/features/medication/data/dose_log_repository.dart';
import 'package:clinic_go/features/medication/data/medication_repository.dart';
import 'package:clinic_go/features/medication/models/medication.dart';
import 'package:clinic_go/features/medication/models/medication_reminder.dart';
import 'package:clinic_go/features/medication/models/scheduled_dose.dart';
import 'package:clinic_go/features/medication/presentation/view_models/daily_doses_view_model.dart';
import 'package:clinic_go/features/medication/services/dose_scheduling_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ── Stub repositories ───────────────────────────────────────────────

class _InMemoryMedicationRepository implements MedicationRepository {
  final List<Medication> medications;
  final List<MedicationReminder> reminders;

  _InMemoryMedicationRepository({this.medications = const [], this.reminders = const []});

  @override
  Future<SavedMedicationResult> addMedication(AddMedicationPayload p) async =>
      const SavedMedicationResult(medicationId: 'id', reminders: []);

  @override
  Future<List<Medication>> fetchMedications() async => medications;

  @override
  Future<void> deleteMedication(String id) async {}

  @override
  Future<List<MedicationReminder>> fetchAllReminders() async => reminders;
}

class _NullDoseLogRepository implements DoseLogRepository {
  @override
  Future<bool> hasDoseLog(String doseId) async => false;

  @override
  Future<void> insertDoseLog({
    required ScheduledDose dose,
    required DoseLogStatus status,
    required DateTime loggedAt,
  }) async {}
}

// ── Test doubles ───────────────────────────────────────────────────

class _LoadingDailyDosesViewModel extends ChangeNotifier
    implements DailyDosesViewModel {
  @override
  bool get isLoading => true;

  @override
  String? get errorMessage => null;

  @override
  List<DoseItem> get doses => [];

  @override
  Future<void> loadTodayDoses() async {}

  @override
  Future<void> logDose({
    required ScheduledDose dose,
    required DoseLogStatus status,
  }) async {}

  @override
  Future<void> refresh() async {}
}

class _EmptyDailyDosesViewModel extends ChangeNotifier
    implements DailyDosesViewModel {
  @override
  bool get isLoading => false;

  @override
  String? get errorMessage => null;

  @override
  List<DoseItem> get doses => [];

  @override
  Future<void> loadTodayDoses() async {}

  @override
  Future<void> logDose({
    required ScheduledDose dose,
    required DoseLogStatus status,
  }) async {}

  @override
  Future<void> refresh() async {}
}

class _SuccessDailyDosesViewModel extends ChangeNotifier
    implements DailyDosesViewModel {
  final List<DoseItem> _doses;

  _SuccessDailyDosesViewModel(this._doses);

  @override
  bool get isLoading => false;

  @override
  String? get errorMessage => null;

  @override
  List<DoseItem> get doses => _doses;

  @override
  Future<void> loadTodayDoses() async {}

  @override
  Future<void> logDose({
    required ScheduledDose dose,
    required DoseLogStatus status,
  }) async {}

  @override
  Future<void> refresh() async {}
}

void main() {
  group('HomeContent Data Structure Tests', () {
    test(
      'DoseItem: [Happy Path] → accepts medication field and copyWith preserves it',
      () {
        final dose = ScheduledDose(
          id: 'd1',
          medicationId: 'm1',
          medicationName: 'Aspirin',
          dosage: '100mg',
          scheduledTime: DateTime.now(),
        );
        final med = Medication(
          id: 'm1',
          userId: 'u1',
          name: 'Aspirin',
          dosage: '100mg',
          frequency: 'Once daily',
          color: Colors.blue,
          createdAt: DateTime.now(),
        );

        final item = DoseItem(dose: dose, medication: med);
        expect(item.dose.medicationName, 'Aspirin');
        expect(item.medication!.name, 'Aspirin');

        final copied = item.copyWith(status: DoseLogStatus.taken);
        expect(copied.medication!.name, 'Aspirin');
        expect(copied.status, DoseLogStatus.taken);
      },
    );

    test(
      'DoseItem: [Empty/Null Case] → medication can be null safely',
      () {
        final dose = ScheduledDose(
          id: 'd1',
          medicationId: 'm1',
          medicationName: 'Aspirin',
          dosage: '100mg',
          scheduledTime: DateTime.now(),
        );

        final item = DoseItem(dose: dose);
        expect(item.medication, isNull);
        expect(item.dose.medicationName, 'Aspirin');

        final copied = item.copyWith();
        expect(copied.medication, isNull);
      },
    );

    test(
      'DoseItem: [Status Update] → copyWith updates status without losing medication',
      () {
        final now = DateTime.now();
        final dose = ScheduledDose(
          id: 'd1',
          medicationId: 'm1',
          medicationName: 'Ibuprofen',
          dosage: '200mg',
          scheduledTime: now,
        );
        final med = Medication(
          id: 'm1',
          userId: 'u1',
          name: 'Ibuprofen',
          dosage: '200mg',
          frequency: 'Twice daily',
          notes: 'With food',
          color: Colors.red,
          createdAt: now,
        );

        final item = DoseItem(dose: dose, medication: med);
        final logged = item.copyWith(
          status: DoseLogStatus.taken,
          takenTime: now,
        );

        expect(logged.medication!.name, 'Ibuprofen');
        expect(logged.status, DoseLogStatus.taken);
        expect(logged.takenTime, now);
      },
    );

    test(
      'DailyDosesViewModel: [Happy Path] → builds lookup map for medications correctly',
      () async {
        final now = DateTime.now();
        final med1 = Medication(
          id: 'm1',
          userId: 'u1',
          name: 'Aspirin',
          dosage: '100mg',
          frequency: 'Once daily',
          color: Colors.blue,
          createdAt: now,
        );
        final med2 = Medication(
          id: 'm2',
          userId: 'u1',
          name: 'Ibuprofen',
          dosage: '200mg',
          frequency: 'Twice daily',
          color: Colors.red,
          createdAt: now,
        );
        final repo = _InMemoryMedicationRepository(
          medications: [med1, med2],
          reminders: [
            MedicationReminder(
              medicationId: 'm1',
              reminderTime: '08:00:00',
              daysOfWeek: ['monday', 'wednesday', 'friday'],
            ),
          ],
        );

        final viewModel = DailyDosesViewModel(
          repository: repo,
          schedulingService: const DoseSchedulingService(),
          logRepository: _NullDoseLogRepository(),
        );

        await viewModel.loadTodayDoses();

        // If today matches one of the reminder days, we should have doses
        final today = DateTime.now();
        final dayName = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'][today.weekday - 1];
        if (['monday', 'wednesday', 'friday'].contains(dayName)) {
          expect(viewModel.doses.isNotEmpty, true);
          // Medication should be attached to dose
          if (viewModel.doses.isNotEmpty) {
            expect(viewModel.doses.first.medication, isNotNull);
            expect(viewModel.doses.first.medication!.name, 'Aspirin');
          }
        }
      },
    );

    test(
      'DoseItem: [Multiple Status Updates] → can transition through states',
      () {
        final dose = ScheduledDose(
          id: 'd1',
          medicationId: 'm1',
          medicationName: 'Test',
          dosage: '50mg',
          scheduledTime: DateTime.now(),
        );
        final med = Medication(
          id: 'm1',
          userId: 'u1',
          name: 'Test',
          dosage: '50mg',
          color: Colors.blue,
          createdAt: DateTime.now(),
        );

        var item = DoseItem(dose: dose, medication: med);

        // Initial state
        expect(item.status, isNull);
        expect(item.isSubmitting, false);

        // Submitting
        item = item.copyWith(isSubmitting: true);
        expect(item.isSubmitting, true);

        // Submitted
        final now = DateTime.now();
        item = item.copyWith(
          status: DoseLogStatus.taken,
          takenTime: now,
          isSubmitting: false,
        );
        expect(item.status, DoseLogStatus.taken);
        expect(item.takenTime, now);
        expect(item.isSubmitting, false);
        expect(item.medication!.name, 'Test'); // Medication preserved
      },
    );
  });
}
