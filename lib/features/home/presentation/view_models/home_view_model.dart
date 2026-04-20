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
  }) : _repository = repository,
       _schedulingService = schedulingService,
       _logRepository = logRepository;

  final MedicationRepository _repository;
  final DoseSchedulingService _schedulingService;
  final DoseLogRepository _logRepository;

  ScheduledDose? _nextDose;
  bool _isOverdue = false;
  bool _isLoading = true;

  ScheduledDose? get nextDose => _nextDose;
  bool get isOverdue => _isOverdue;
  bool get isLoading => _isLoading;

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
    } catch (e) {
      debugPrint('Error loading next dose in HomeViewModel: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
