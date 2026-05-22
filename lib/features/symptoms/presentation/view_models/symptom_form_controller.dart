import 'package:clinic_go/core/providers/supabase_providers.dart';
import 'package:clinic_go/features/symptoms/data/symptom_repository.dart';
import 'package:clinic_go/features/symptoms/presentation/view_models/symptom_form_state.dart';
import 'package:clinic_go/features/symptoms/presentation/view_models/symptom_history_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final symptomFormControllerProvider =
    NotifierProvider<SymptomFormController, SymptomFormState>(
      SymptomFormController.new,
    );

class SymptomFormController extends Notifier<SymptomFormState> {
  late final SymptomRepository _repository;

  static const commonSymptoms = [
    'headache',
    'nausea',
    'fatigue',
    'dizziness',
    'fever',
    'cough',
    'shortness_of_breath',
    'anxiety',
    'sadness',
    'muscle_pain',
    'joint_pain',
    'stomach_pain',
    'insomnia',
    'brain_fog',
  ];

  @override
  SymptomFormState build() {
    _repository = ref.read(symptomRepositoryProvider);
    return SymptomFormState.initial();
  }

  List<String> get filteredSymptoms {
    final query = state.searchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return commonSymptoms;
    }

    return commonSymptoms
        .where((symptom) => symptom.replaceAll('_', ' ').contains(query))
        .toList();
  }

  void selectSymptom(String symptom) {
    state = state.copyWith(
      selectedSymptom: symptom,
      isDirty: true,
      errorMessage: null,
    );
  }

  void setSeverity(double value) {
    state = state.copyWith(
      severity: value.round().clamp(1, 10),
      isDirty: true,
      errorMessage: null,
    );
  }

  void setNotes(String value) {
    state = state.copyWith(notes: value, isDirty: true, errorMessage: null);
  }

  void setSearchQuery(String value) {
    state = state.copyWith(searchQuery: value);
  }

  void setOccurredAt(DateTime value) {
    state = state.copyWith(
      occurredAt: value,
      isDirty: true,
      errorMessage: null,
    );
  }

  Future<bool> submitSymptomLog() async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      state = state.copyWith(
        errorMessage: 'Inicia sessão para guardar um registo de sintomas.',
      );
      return false;
    }

    if (state.selectedSymptom == null) {
      state = state.copyWith(errorMessage: 'Seleciona pelo menos um sintoma.');
      return false;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      await _repository.insertSymptomLog(
        userId: user.id,
        symptomType: state.selectedSymptom!,
        severity: state.severity,
        notes: state.notes,
        occurredAt: state.occurredAt,
      );
      ref.invalidate(symptomHistoryProvider);
      state = SymptomFormState.initial();
      return true;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage:
            'Não foi possível guardar o sintoma. Verifica a tua ligação.',
      );
      return false;
    }
  }
}
