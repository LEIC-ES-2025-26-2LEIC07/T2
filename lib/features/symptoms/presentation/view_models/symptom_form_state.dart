class SymptomFormState {
  const SymptomFormState({
    required this.selectedSymptom,
    required this.severity,
    required this.notes,
    required this.occurredAt,
    required this.searchQuery,
    required this.isDirty,
    required this.isLoading,
    required this.errorMessage,
  });

  final String? selectedSymptom;
  final int severity;
  final String notes;
  final DateTime occurredAt;
  final String searchQuery;
  final bool isDirty;
  final bool isLoading;
  final String? errorMessage;

  static const _sentinel = Object();

  factory SymptomFormState.initial() {
    return SymptomFormState(
      selectedSymptom: null,
      severity: 3,
      notes: '',
      occurredAt: DateTime.now(),
      searchQuery: '',
      isDirty: false,
      isLoading: false,
      errorMessage: null,
    );
  }

  bool get canSubmit => selectedSymptom != null && !isLoading;

  SymptomFormState copyWith({
    Object? selectedSymptom = _sentinel,
    int? severity,
    String? notes,
    DateTime? occurredAt,
    String? searchQuery,
    bool? isDirty,
    bool? isLoading,
    Object? errorMessage = _sentinel,
  }) {
    return SymptomFormState(
      selectedSymptom: identical(selectedSymptom, _sentinel)
          ? this.selectedSymptom
          : selectedSymptom as String?,
      severity: severity ?? this.severity,
      notes: notes ?? this.notes,
      occurredAt: occurredAt ?? this.occurredAt,
      searchQuery: searchQuery ?? this.searchQuery,
      isDirty: isDirty ?? this.isDirty,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}
