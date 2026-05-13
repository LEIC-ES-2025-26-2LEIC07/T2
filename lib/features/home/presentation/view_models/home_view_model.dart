import 'package:flutter/foundation.dart';
import 'package:clinic_go/features/medication/models/scheduled_dose.dart';
import 'package:clinic_go/features/medication/services/dose_scheduling_service.dart';
import 'package:clinic_go/features/medication/services/missed_dose_notification_controller.dart';
import 'package:clinic_go/features/medication/data/medication_repository.dart';
import 'package:clinic_go/features/medication/data/dose_log_repository.dart';

class HomeViewModel extends ChangeNotifier {
  HomeViewModel({
    required MedicationRepository repository,
    required DoseSchedulingService schedulingService,
    required DoseLogRepository logRepository,
    MissedDoseNotificationController? notificationController,
  }) : _repository = repository,
       _schedulingService = schedulingService,
       _logRepository = logRepository,
       _notificationController = notificationController;

  final MedicationRepository _repository;
  final DoseSchedulingService _schedulingService;
  final DoseLogRepository _logRepository;
  final MissedDoseNotificationController? _notificationController;

  ScheduledDose? _nextDose;
  bool _isOverdue = false;
  bool _isLoading = true;
  bool _isLoggingDose = false;
  bool _hadDosesToday = false;
  bool _disposed = false;
  final Set<String> _locallyLoggedDoseIds = {};

  ScheduledDose? get nextDose => _nextDose;
  bool get isOverdue => _isOverdue;
  bool get isLoading => _isLoading;
  bool get isLoggingDose => _isLoggingDose;
  bool get hadDosesToday => _hadDosesToday;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void doseLogged() {
    _nextDose = null;
    _isOverdue = false;
    if (!_disposed) notifyListeners();
  }

  Future<void> logDose({
    required ScheduledDose dose,
    required DoseLogStatus status,
  }) async {
    final prevDose = _nextDose;
    final prevOverdue = _isOverdue;

    _nextDose = null;
    _isOverdue = false;
    _isLoggingDose = true;
    if (!_disposed) notifyListeners();

    try {
      final now = DateTime.now();
      if (_notificationController != null) {
        await _notificationController.logDose(
          dose: dose,
          status: status,
          loggedAt: now,
        );
      } else {
        await _logRepository.insertDoseLog(
          dose: dose,
          status: status,
          loggedAt: now,
        );
      }
      _locallyLoggedDoseIds.add(dose.id);
      _isLoggingDose = false;
      await loadNextDose();
    } catch (e) {
      _nextDose = prevDose;
      _isOverdue = prevOverdue;
      _isLoggingDose = false;
      if (!_disposed) notifyListeners();
      rethrow;
    }
  }

  Future<void> loadNextDose() async {
    _isLoading = true;
    if (!_disposed) notifyListeners();

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

      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = DateTime(now.year, now.month, now.day + 1);
      _hadDosesToday = allUpcoming.any(
        (d) =>
            !d.scheduledTime.isBefore(todayStart) &&
            d.scheduledTime.isBefore(todayEnd),
      );

      // Filter out doses already logged (remote check + local optimistic set)
      final pendingDoses = <ScheduledDose>[];
      for (final dose in allUpcoming) {
        if (_locallyLoggedDoseIds.contains(dose.id)) continue;
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
      _nextDose = null;
      _isOverdue = false;
    } finally {
      _isLoading = false;
      if (!_disposed) notifyListeners();
    }
  }
}
