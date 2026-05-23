import 'package:flutter/material.dart';
import 'package:clinic_go/features/medication/data/medication_repository.dart';
import 'package:clinic_go/features/medication/models/medication.dart';
import 'package:clinic_go/features/medication/presentation/view_models/medication_form_mixin.dart';

/// A reminder slot in the edit form — wraps an existing ID (if any) and time.
class ReminderSlot {
  ReminderSlot({this.id, required this.time});

  /// Null for slots that have not been persisted yet.
  final String? id;
  TimeOfDay time;
}

class EditMedicationViewModel extends ChangeNotifier with MedicationFormFields {
  EditMedicationViewModel({
    required MedicationRepository repository,
    required Medication medication,
  }) : _repository = repository,
       _medicationId = medication.id {
    name = medication.name;
    dosageAmount = medication.dosageAmount;
    dosageUnit = medication.dosageUnit ?? 'mg';
    frequency = _parseMedicationFrequency(medication.frequency);
    selectedColor = medication.color;
    startDate = medication.startDate;
    endDate = medication.endDate;
    notes = medication.notes ?? '';
    withFood = medication.withFood;
  }

  final MedicationRepository _repository;
  final String _medicationId;

  List<ReminderSlot> _reminderSlots = [];
  final List<String> _remindersToDelete = [];

  List<ReminderSlot> get reminderSlots => List.unmodifiable(_reminderSlots);

  bool isLoadingReminders = true;
  bool wasDeleted = false;

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

  // ── Frequency + reminder sync ────────────────────────────────────
  void setFrequency(String? v) {
    if (v == null || v == frequency) return;
    frequency = v;
    _syncReminderSlots();
    isDirty = true;
    notifyListeners();
  }

  void setIntervalDays(int v) {
    if (v < 1) return;
    frequency = 'interval:$v';
    _syncReminderSlots();
    isDirty = true;
    notifyListeners();
  }

  static String _parseMedicationFrequency(String? stored) {
    if (stored == null) return 'interval:1';
    if (stored.startsWith('interval:')) return stored;
    switch (stored) {
      case 'Em dias alternados':
        return 'interval:2';
      case 'Semanalmente':
        return 'interval:7';
      default:
        return 'interval:1';
    }
  }

  void setReminderTime(int index, TimeOfDay time) {
    if (index < _reminderSlots.length) {
      _reminderSlots[index].time = time;
      isDirty = true;
      notifyListeners();
    }
  }

  void _syncReminderSlots() {
    final target = slotsFor(frequency);
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

  // ── Submit ───────────────────────────────────────────────────────
  Future<void> submit() async {
    if (!validateForm()) return;

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
      errorMessage = 'Não foi possível guardar as alterações. Tenta novamente.';
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
      errorMessage =
          'Não foi possível eliminar o medicamento. Tenta novamente.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
