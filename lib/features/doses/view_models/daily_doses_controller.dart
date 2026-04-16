import 'package:flutter/foundation.dart';

import '../data/dose_log_repository.dart';
import '../models/scheduled_dose.dart';

class DailyDosesController extends ChangeNotifier {
  DailyDosesController({
    required DoseLogRepository repository,
    required List<ScheduledDose> initialDoses,
  }) : _repository = repository,
       _doses = List.unmodifiable(initialDoses);

  final DoseLogRepository _repository;
  List<ScheduledDose> _doses;

  List<ScheduledDose> get doses => _doses;

  Future<void> logDose({
    required String doseId,
    required DoseStatus status,
  }) async {
    final previousDoses = _doses;
    final doseIndex = previousDoses.indexWhere((dose) => dose.id == doseId);

    if (doseIndex == -1 || previousDoses[doseIndex].isCompleted) {
      return;
    }

    final loggedAt = DateTime.now();
    final updatedDose = previousDoses[doseIndex].copyWith(
      status: status,
      loggedAt: loggedAt,
    );
    final optimisticDoses = [...previousDoses];
    optimisticDoses[doseIndex] = updatedDose;

    _doses = List.unmodifiable(optimisticDoses);
    notifyListeners();

    try {
      await _repository.logDose(
        medicationId: updatedDose.medicationId,
        scheduledTime: updatedDose.scheduledTime,
        loggedAt: loggedAt,
        status: status,
      );
    } catch (_) {
      _doses = previousDoses;
      notifyListeners();
      rethrow;
    }
  }
}
