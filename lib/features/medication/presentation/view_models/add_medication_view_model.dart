import 'package:flutter/material.dart';
import 'package:clinic_go/core/themes/app_colors.dart';
import 'package:clinic_go/features/medication/data/medication_repository.dart';
import 'package:clinic_go/features/medication/services/missed_dose_notification_controller.dart';
import 'package:clinic_go/features/medication/services/dose_scheduling_service.dart';
import 'package:clinic_go/features/medication/models/medication.dart';

/// ViewModel for the Add Medication form.
///
/// Owns all form field state, validation, color selection, and async submission.
/// Uses [ChangeNotifier] to match the repo's existing state-management pattern.
class AddMedicationViewModel extends ChangeNotifier {
  AddMedicationViewModel({
    required MedicationRepository repository,
    required MissedDoseNotificationController notificationController,
    required DoseSchedulingService schedulingService,
  }) : _repository = repository,
       _notificationController = notificationController,
       _schedulingService = schedulingService;

  final MedicationRepository _repository;
  final MissedDoseNotificationController _notificationController;
  final DoseSchedulingService _schedulingService;

  // ── Form fields ──────────────────────────────────────────────────
  String name = '';
  String dosage = '';
  String frequency = frequencyOptions.first;
  Color selectedColor = AppColors.lemon;
  List<TimeOfDay> reminderTimes = [const TimeOfDay(hour: 8, minute: 0)];
  List<String> daysOfWeek = _allDays;
  DateTime? startDate;
  DateTime? endDate;
  String notes = '';
  bool withFood = false;

  // ── Validation ───────────────────────────────────────────────────
  String? nameError;
  String? dosageError;

  // ── Async state ──────────────────────────────────────────────────
  bool isLoading = false;
  String? errorMessage;
  bool isSuccess = false;

  /// True once any field has been edited — drives the discard-changes dialog.
  bool isDirty = false;

  // ── Constants ────────────────────────────────────────────────────
  static const List<String> frequencyOptions = [
    'Once daily',
    'Twice daily',
    'Three times daily',
    'Every other day',
    'Weekly',
    'As needed',
  ];

  static const List<String> _allDays = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];

  /// Color palette shown in the bottom-sheet picker — uses the app's design tokens.
  static const List<Color> colorPalette = [
    AppColors.lemon,  // primary blue
    AppColors.ink,    // deep navy
    AppColors.coral,  // muted salmon
    AppColors.mint,   // soft sage
    AppColors.sky,    // pale clinical blue
    AppColors.rose,   // pale steel
    AppColors.statusTeal,  // teal
    AppColors.statusNight, // dark slate
  ];

  // ── Setters ──────────────────────────────────────────────────────
  void setName(String v) {
    name = v;
    nameError = null;
    isDirty = true;
    notifyListeners();
  }

  void setDosage(String v) {
    dosage = v;
    dosageError = null;
    isDirty = true;
    notifyListeners();
  }

  void setFrequency(String? v) {
    if (v == null || v == frequency) return;
    frequency = v;
    _syncReminderSlots();
    isDirty = true;
    notifyListeners();
  }

  void setColor(Color color) {
    selectedColor = color;
    isDirty = true;
    notifyListeners();
  }

  void setReminderTime(int index, TimeOfDay time) {
    if (index < reminderTimes.length) {
      reminderTimes = List.of(reminderTimes)..[index] = time;
      isDirty = true;
      notifyListeners();
    }
  }

  void setStartDate(DateTime? date) {
    startDate = date;
    isDirty = true;
    notifyListeners();
  }

  void setEndDate(DateTime? date) {
    endDate = date;
    isDirty = true;
    notifyListeners();
  }

  void setNotes(String v) {
    notes = v;
    isDirty = true;
    notifyListeners();
  }

  void setWithFood(bool v) {
    withFood = v;
    isDirty = true;
    notifyListeners();
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }

  // ── Submission ───────────────────────────────────────────────────
  Future<void> submit() async {
    if (!_validate()) return;

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final result = await _repository.addMedication(
        AddMedicationPayload(
          name: name.trim(),
          dosage: dosage.trim(),
          frequency: frequency,
          color: selectedColor,
          reminderTimes: reminderTimes
              .map(
                (t) =>
                    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00',
              )
              .toList(),
          daysOfWeek: daysOfWeek,
          startDate: startDate,
          endDate: endDate,
          notes: notes.trim().isEmpty ? null : notes.trim(),
          withFood: withFood,
        ),
      );

      // ── Step 2: Schedule notifications for the next 24 hours ────────
      await _scheduleInitialNotifications(result);

      isSuccess = true;
      isDirty = false;
    } on MedicationSaveException catch (e) {
      debugPrint('MedicationSaveException: ${e.message}');
      errorMessage = e.message;
    } catch (e, stackTrace) {
      debugPrint('Error saving medication: $e\n$stackTrace');
      errorMessage = 'Could not save medication. Please try again.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────
  bool _validate() {
    nameError = null;
    dosageError = null;
    bool valid = true;

    if (name.trim().isEmpty) {
      nameError = 'Name is required';
      valid = false;
    }
    if (dosage.trim().isEmpty) {
      dosageError = 'Dosage is required';
      valid = false;
    }
    if (!valid) notifyListeners();
    return valid;
  }

  void _syncReminderSlots() {
    final target = _slotsFor(frequency);
    if (target > reminderTimes.length) {
      reminderTimes = [
        ...reminderTimes,
        ...List.generate(
          target - reminderTimes.length,
          (_) => const TimeOfDay(hour: 12, minute: 0),
        ),
      ];
    } else {
      reminderTimes = reminderTimes.sublist(0, target);
    }
  }

  int _slotsFor(String freq) {
    switch (freq) {
      case 'Twice daily':
        return 2;
      case 'Three times daily':
        return 3;
      default:
        return 1;
    }
  }

  Future<void> _scheduleInitialNotifications(
    SavedMedicationResult result,
  ) async {
    final medication = Medication(
      id: result.medicationId,
      userId: '',
      name: name.trim(),
      dosage: dosage.trim(),
      color: selectedColor,
      frequency: frequency,
      startDate: startDate,
      endDate: endDate,
      createdAt: DateTime.now(),
    );

    final upcomingDoses = _schedulingService.calculateUpcomingDoses(
      medication,
      result.reminders,
    );

    for (final dose in upcomingDoses) {
      await _notificationController.scheduleDoseReminder(dose);
    }
  }
}
