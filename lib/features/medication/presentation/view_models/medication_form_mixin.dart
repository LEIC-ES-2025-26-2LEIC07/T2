import 'package:flutter/material.dart';
import 'package:clinic_go/core/themes/app_colors.dart';

/// Shared form-field state, simple setters, validation, and slot-count helper
/// for both [AddMedicationViewModel] and [EditMedicationViewModel].
mixin MedicationFormFields on ChangeNotifier {
  // ── Form fields ──────────────────────────────────────────────────
  String name = '';
  int? dosageAmount;
  String dosageUnit = 'mg';
  String frequency =
      'Uma vez por dia'; // matches AddMedicationViewModel.frequencyOptions.first
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

  bool isDirty = false;
  String? nameError;
  String? dosageError;
  bool isLoading = false;
  String? errorMessage;
  bool isSuccess = false;

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

  void setColor(Color color) {
    selectedColor = color;
    isDirty = true;
    notifyListeners();
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

  // ── Validation ───────────────────────────────────────────────────
  bool validateForm() {
    nameError = null;
    dosageError = null;
    bool valid = true;
    if (name.trim().isEmpty) {
      nameError = 'O nome é obrigatório';
      valid = false;
    }
    if (dosageAmount == null || dosageAmount! <= 0) {
      dosageError = 'Introduz uma dosagem válida';
      valid = false;
    }
    if (!valid) notifyListeners();
    return valid;
  }

  // ── Slot-count helper ─────────────────────────────────────────────
  int slotsFor(String freq) {
    switch (freq) {
      case 'Duas vezes por dia':
        return 2;
      case 'Três vezes por dia':
        return 3;
      default:
        return 1;
    }
  }
}
