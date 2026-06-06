import 'package:flutter/material.dart';
import 'package:clinic_go/core/themes/app_colors.dart';
import 'package:clinic_go/features/medication/data/medication_repository.dart';
import 'package:clinic_go/features/medication/presentation/view_models/medication_form_mixin.dart';

class AddMedicationViewModel extends ChangeNotifier with MedicationFormFields {
  AddMedicationViewModel({required MedicationRepository repository})
    : _repository = repository;

  final MedicationRepository _repository;

  List<TimeOfDay> reminderTimes = [const TimeOfDay(hour: 8, minute: 0)];

  // ── Constants ────────────────────────────────────────────────────
  static const List<String> frequencyOptions = [
    'Uma vez por dia',
    'Duas vezes por dia',
    'Três vezes por dia',
    'Em dias alternados',
    'Semanalmente',
    'Conforme necessário',
  ];

  static const List<String> dosageUnits = ['mg', 'g', 'ml', 'mcg', 'IU'];

  static const List<Color> colorPalette = [
    AppColors.lemon,
    AppColors.ink,
    AppColors.coral,
    AppColors.mint,
    AppColors.sky,
    AppColors.rose,
    AppColors.statusTeal,
    AppColors.statusNight,
  ];

  // ── Frequency + reminder sync ────────────────────────────────────
  void setFrequency(String? v) {
    if (v == null || v == frequency) return;
    frequency = v;
    _syncReminderSlots();
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

  void _syncReminderSlots() {
    final target = slotsFor(frequency);
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

  // ── Submission ───────────────────────────────────────────────────
  Future<void> submit() async {
    if (!validateForm()) return;

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _repository.addMedication(
        AddMedicationPayload(
          name: name.trim(),
          dosageAmount: dosageAmount!,
          dosageUnit: dosageUnit,
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

      isSuccess = true;
      isDirty = false;
    } on MedicationSaveException catch (e) {
      debugPrint('MedicationSaveException: ${e.message}');
      errorMessage = e.message;
    } catch (e, stackTrace) {
      debugPrint('Error saving medication: $e\n$stackTrace');
      errorMessage = 'Não foi possível guardar o medicamento. Tenta novamente.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
