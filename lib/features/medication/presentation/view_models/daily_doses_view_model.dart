import 'package:flutter/foundation.dart';

import 'package:clinic_go/features/medication/models/scheduled_dose.dart';
import 'package:clinic_go/features/medication/data/medication_repository.dart';
import 'package:clinic_go/features/medication/services/dose_scheduling_service.dart';
import 'package:clinic_go/features/medication/data/dose_log_repository.dart';

class DoseItem {
  DoseItem({required this.dose});

  final ScheduledDose dose;
  DoseLogStatus? status;
  DateTime? takenTime;
  bool isSubmitting = false;

  DoseItem copyWith({
    DoseLogStatus? status,
    DateTime? takenTime,
    bool? isSubmitting,
  }) {
    final out = DoseItem(dose: dose)
      ..status = status ?? this.status
      ..takenTime = takenTime ?? this.takenTime
      ..isSubmitting = isSubmitting ?? this.isSubmitting;
    return out;
  }
}

class DailyDosesViewModel extends ChangeNotifier {
  DailyDosesViewModel({
    required MedicationRepository repository,
    required DoseSchedulingService schedulingService,
    required DoseLogRepository logRepository,
  }) : _repository = repository,
       _schedulingService = schedulingService,
       _logRepository = logRepository;

  final MedicationRepository _repository;
  final DoseSchedulingService _schedulingService;
  final DoseLogRepository _logRepository;

  bool _isLoading = false;
  String? _errorMessage;
  List<DoseItem> _doses = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<DoseItem> get doses => List.unmodifiable(_doses);

  Future<void> loadTodayDoses() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final medications = await _repository.fetchMedications();
      final reminders = await _repository.fetchAllReminders();

      final now = DateTime.now();
      final allUpcoming = <ScheduledDose>[];

      for (final med in medications) {
        final medReminders = reminders.where((r) => r.medicationId == med.id);
        allUpcoming.addAll(
          _schedulingService.calculateUpcomingDoses(
            med,
            medReminders.toList(),
            from: DateTime(now.year, now.month, now.day),
            duration: const Duration(days: 1),
          ),
        );
      }

      final pending = <DoseItem>[];
      for (final dose in allUpcoming) {
        final already = await _safeHasDoseLog(dose.id);
        if (!already) {
          pending.add(DoseItem(dose: dose));
        }
      }

      _doses = pending;
    } catch (e) {
      _errorMessage = 'Failed to load today\'s schedule.';
      debugPrint('DailyDosesViewModel.loadTodayDoses error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => loadTodayDoses();

  Future<void> logDose({
    required ScheduledDose dose,
    required DoseLogStatus status,
  }) async {
    final index = _doses.indexWhere((d) => d.dose.id == dose.id);
    if (index == -1) {
      throw StateError('Dose not found');
    }

    final prev = _doses[index];
    final previousState = prev.copyWith();

    // Optimistic update
    _doses[index] = prev.copyWith(
      status: status,
      takenTime: DateTime.now(),
      isSubmitting: true,
    );
    notifyListeners();

    try {
      await _logRepository.insertDoseLog(
        dose: dose,
        status: status,
        loggedAt: DateTime.now(),
      );

      // mark not submitting
      _doses[index] = _doses[index].copyWith(isSubmitting: false);
      notifyListeners();
    } catch (e) {
      // rollback
      _doses[index] = previousState;
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> _safeHasDoseLog(String doseId) async {
    try {
      return await _logRepository.hasDoseLog(doseId);
    } catch (e) {
      debugPrint('DailyDosesViewModel._safeHasDoseLog error: $e');
      return false;
    }
  }
}
