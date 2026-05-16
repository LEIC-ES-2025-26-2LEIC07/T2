import 'package:flutter/material.dart';
import 'package:clinic_go/core/themes/app_colors.dart';
import 'package:clinic_go/features/medication/data/medication_repository.dart';
import 'package:clinic_go/features/medication/models/medication.dart';
import 'package:clinic_go/features/medication/presentation/view_models/add_medication_view_model.dart';

/// A reminder slot in the edit form — wraps an existing ID (if any) and time.
class ReminderSlot {
  ReminderSlot({this.id, required this.time});

  /// Null for slots that have not been persisted yet.
  final String? id;
  TimeOfDay time;
}

/// ViewModel for the Edit Medication form.
///
/// Pre-populates from [medication], fetches existing reminders via the
/// repository, and exposes submit/delete mutations.
class EditMedicationViewModel extends ChangeNotifier {
  EditMedicationViewModel({
    required MedicationRepository repository,
    required Medication medication,
  }) : _repository = repository,
       _medicationId = medication.id {
    name = medication.name;
    dosageAmount = medication.dosageAmount;
    dosageUnit = medication.dosageUnit ?? 'mg';
    frequency =
        AddMedicationViewModel.frequencyOptions.contains(medication.frequency)
        ? medication.frequency!
        : AddMedicationViewModel.frequencyOptions.first;
    selectedColor = medication.color;
    startDate = medication.startDate;
    endDate = medication.endDate;
    notes = medication.notes ?? '';
    withFood = medication.withFood;
  }

  final MedicationRepository _repository;
  final String _medicationId;

  // ── Form fields ──────────────────────────────────────────────────
  String name = '';
  int? dosageAmount;
  String dosageUnit = 'mg';
  String frequency = AddMedicationViewModel.frequencyOptions.first;
  Color selectedColor = AppColors.lemon;
  bool withFood = false;
  List<String> daysOfWeek = const [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];
  DateTime? startDate;
  DateTime? endDate;
  String notes = '';

  List<ReminderSlot> _reminderSlots = [];
  final List<String> _remindersToDelete = [];

  List<ReminderSlot> get reminderSlots => List.unmodifiable(_reminderSlots);

  // ── Validation ───────────────────────────────────────────────────
  String? nameError;
  String? dosageError;

  // ── Async state ──────────────────────────────────────────────────
  bool isLoadingReminders = true;
  bool isLoading = false;
  String? errorMessage;
  bool isSuccess = false;
  bool wasDeleted = false;
  bool isDirty = false;

  // ── Init ─────────────────────────────────────────────────────────
  Future<void> loadReminders() async {
    isLoadingReminders = true;
    notifyListeners();
    try {
      final reminders = await _repository.fetchRemindersForMedication(
        _medicationId,
      );
      _reminderSlots = reminders.map((r) {
        final parts = r.reminderTime.split(':');
        return ReminderSlot(
          id: r.id,
          time: TimeOfDay(
            hour: int.parse(parts[0]),
            minute: int.parse(parts[1]),
          ),
        );
      }).toList();
      if (_reminderSlots.isEmpty) {
        _reminderSlots = [
          ReminderSlot(time: const TimeOfDay(hour: 8, minute: 0)),
        ];
      }
      if (reminders.isNotEmpty) {
        daysOfWeek = reminders.first.daysOfWeek;
      }
    } catch (_) {
      _reminderSlots = [
        ReminderSlot(time: const TimeOfDay(hour: 8, minute: 0)),
      ];
    } finally {
      isLoadingReminders = false;
      notifyListeners();
    }
  }

  // ── Setters ──────────────────────────────────────────────────────
  void setName(String v) {
    name = v;
    nameError = null;
    isDirty = true;
    notifyListeners();
  }

  void setDosageAmount(int? v) {
    dosageAmount = v;
    dosageError = null;
    isDirty = true;
    notifyListeners();
  }

  void setDosageUnit(String v) {
    dosageUnit = v;
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
    if (index < _reminderSlots.length) {
      _reminderSlots[index].time = time;
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

  // ── Submit ───────────────────────────────────────────────────────
  Future<void> submit() async {
    if (!_validate()) return;

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final remindersToUpsert = _reminderSlots.map((slot) {
        final time =
            '${slot.time.hour.toString().padLeft(2, '0')}:'
            '${slot.time.minute.toString().padLeft(2, '0')}:00';
        return <String, dynamic>{
          if (slot.id != null) 'id': slot.id,
          'medication_id': _medicationId,
          'reminder_time': time,
          'days_of_week': daysOfWeek,
          'is_active': true,
        };
      }).toList();

      await _repository.editMedication(
        EditMedicationPayload(
          medicationId: _medicationId,
          name: name.trim(),
          dosageAmount: dosageAmount!,
          dosageUnit: dosageUnit,
          frequency: frequency,
          color: selectedColor,
          daysOfWeek: daysOfWeek,
          remindersToUpsert: remindersToUpsert,
          remindersToDelete: List.of(_remindersToDelete),
          startDate: startDate,
          endDate: endDate,
          notes: notes.trim().isEmpty ? null : notes.trim(),
          withFood: withFood,
        ),
      );

      isSuccess = true;
      isDirty = false;
    } catch (e) {
      debugPrint('Edit medication error: $e');
      errorMessage = 'Could not save changes. Please try again.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteMedication() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _repository.deleteMedication(_medicationId);
      wasDeleted = true;
      isSuccess = true;
    } catch (e) {
      debugPrint('Delete medication error: $e');
      errorMessage = 'Could not delete medication. Please try again.';
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
    if (dosageAmount == null || dosageAmount! <= 0) {
      dosageError = 'Enter a valid dosage';
      valid = false;
    }
    if (!valid) notifyListeners();
    return valid;
  }

  void _syncReminderSlots() {
    final target = _slotsFor(frequency);
    if (target > _reminderSlots.length) {
      _reminderSlots = [
        ..._reminderSlots,
        ...List.generate(
          target - _reminderSlots.length,
          (_) => ReminderSlot(time: const TimeOfDay(hour: 12, minute: 0)),
        ),
      ];
    } else if (target < _reminderSlots.length) {
      final removed = _reminderSlots.sublist(target);
      for (final slot in removed) {
        if (slot.id != null) _remindersToDelete.add(slot.id!);
      }
      _reminderSlots = _reminderSlots.sublist(0, target);
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
}
