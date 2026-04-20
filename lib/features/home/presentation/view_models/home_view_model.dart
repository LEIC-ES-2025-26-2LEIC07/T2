import 'package:clinic_go/features/medication/services/missed_dose_notification_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:clinic_go/features/medication/models/scheduled_dose.dart';
import 'package:clinic_go/features/medication/services/dose_scheduling_service.dart';
import 'package:clinic_go/features/medication/data/medication_repository.dart';
import 'package:clinic_go/features/medication/data/dose_log_repository.dart';

class HomeViewModel extends ChangeNotifier {
  HomeViewModel({
    required MedicationRepository repository,
    required DoseSchedulingService schedulingService,
    required DoseLogRepository logRepository,
    required MissedDoseNotificationController notificationController,
  }) : _repository = repository,
       _schedulingService = schedulingService,
       _logRepository = logRepository,
       _notificationController = notificationController;

  final MedicationRepository _repository;
  final DoseSchedulingService _schedulingService;
  final DoseLogRepository _logRepository;
  final MissedDoseNotificationController _notificationController;

  ScheduledDose? _nextDose;
  bool _isOverdue = false;
  bool _isLoading = true;
  String? _errorMessage;

  ScheduledDose? get nextDose => _nextDose;
  bool get isOverdue => _isOverdue;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> loadNextDose() async {
    _isLoading = true;
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
            // Look back 2 hours for overdue and forward 24 hours for upcoming
            from: now.subtract(const Duration(hours: 2)),
            duration: const Duration(hours: 26),
          ),
        );
      }

      // Filter out doses already logged
      final pendingDoses = <ScheduledDose>[];
      for (final dose in allUpcoming) {
        if (!await _logRepository.hasDoseLog(dose.id)) {
          pendingDoses.add(dose);
        }
      }

      if (pendingDoses.isNotEmpty) {
        pendingDoses.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
        _nextDose = pendingDoses.first;
        _isOverdue = _nextDose!.scheduledTime.isBefore(now);
      } else {
        _nextDose = null;
        _isOverdue = false;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logDose(ScheduledDose dose, DoseLogStatus status) async {
    // Optimistic update
    final previousNextDose = _nextDose;
    final previousIsOverdue = _isOverdue;

    _nextDose = null;
    _isOverdue = false;
    _errorMessage = null;
    notifyListeners();

    try {
      await _notificationController.logDose(dose: dose, status: status);
      // Success: we just need to load the *actual* next dose now to be sure
      await loadNextDose();
    } catch (e) {
      // Rollback
      _nextDose = previousNextDose;
      _isOverdue = previousIsOverdue;
      _errorMessage = 'Failed to log dose. Please try again.';
      notifyListeners();
      rethrow;
    }
  }
}
