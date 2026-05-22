import 'package:flutter/foundation.dart';
import 'package:clinic_go/features/medication/models/medication.dart';
import 'package:clinic_go/features/medication/data/medication_repository.dart';

/// ViewModel for the Medications list screen.
class MedicationsListViewModel extends ChangeNotifier {
  MedicationsListViewModel({required MedicationRepository repository})
    : _repository = repository;

  final MedicationRepository _repository;

  List<Medication> _medications = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Medication> get medications => List.unmodifiable(_medications);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  Future<void> loadMedications() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _medications = await _repository.fetchMedications();
    } catch (_) {
      _errorMessage = 'Could not load medications. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteMedication(String id) async {
    try {
      await _repository.deleteMedication(id);
      _medications = _medications.where((med) => med.id != id).toList();
    } catch (_) {
      rethrow;
    } finally {
      notifyListeners();
    }
  }
}
