import 'package:clinic_go/ui/home/data/dose_logs_repository.dart';
import 'package:clinic_go/ui/home/models/dose_log_entry.dart';
import 'package:clinic_go/ui/home/models/scheduled_dose.dart';
import 'package:flutter/foundation.dart';

enum DoseLogOutcome { success, failure, authRequired, ignored }

class DoseLogResult {
  const DoseLogResult({required this.outcome, this.message});

  final DoseLogOutcome outcome;
  final String? message;
}

class DailyDosesController extends ChangeNotifier {
  DailyDosesController({
    required DoseLogsRepository repository,
    required List<ScheduledDose> initialDoses,
    DateTime Function()? clock,
  }) : _repository = repository,
       _clock = clock ?? DateTime.now,
       _doses = List<ScheduledDose>.from(initialDoses);

  final DoseLogsRepository _repository;
  final DateTime Function() _clock;
  List<ScheduledDose> _doses;

  List<ScheduledDose> get doses => List<ScheduledDose>.unmodifiable(_doses);
  bool get isAuthenticated => _repository.isAuthenticated;

  Future<DoseLogResult> logDose({
    required String medicationId,
    required DateTime scheduledTime,
    required DoseLogStatus status,
  }) async {
    final index = _doses.indexWhere(
      (dose) =>
          dose.medicationId == medicationId &&
          dose.scheduledTime.isAtSameMomentAs(scheduledTime),
    );

    if (index == -1) {
      return const DoseLogResult(
        outcome: DoseLogOutcome.failure,
        message: 'Nao foi possivel encontrar esta toma.',
      );
    }

    if (!_repository.isAuthenticated) {
      return const DoseLogResult(
        outcome: DoseLogOutcome.authRequired,
        message: 'Inicia sessão para registar a tua medicação.',
      );
    }

    final currentDose = _doses[index];
    if (currentDose.isCompleted || currentDose.isSyncing) {
      return const DoseLogResult(outcome: DoseLogOutcome.ignored);
    }

    final loggedAt = _clock();
    final previousDose = currentDose;
    _doses[index] = currentDose.copyWith(
      status: status,
      loggedAt: loggedAt,
      isSyncing: true,
    );
    notifyListeners();

    try {
      await _repository.insertDoseLog(
        DoseLogEntry(
          medicationId: medicationId,
          scheduledTime: scheduledTime,
          loggedAt: loggedAt,
          status: status,
        ),
      );

      _doses[index] = _doses[index].copyWith(isSyncing: false);
      notifyListeners();

      return const DoseLogResult(outcome: DoseLogOutcome.success);
    } on DoseLogException catch (error) {
      _doses[index] = previousDose;
      notifyListeners();

      return DoseLogResult(
        outcome: _repository.isAuthenticated
            ? DoseLogOutcome.failure
            : DoseLogOutcome.authRequired,
        message: error.message,
      );
    } catch (_) {
      _doses[index] = previousDose;
      notifyListeners();

      return const DoseLogResult(
        outcome: DoseLogOutcome.failure,
        message: 'Nao foi possivel guardar o registo da toma.',
      );
    }
  }
}
