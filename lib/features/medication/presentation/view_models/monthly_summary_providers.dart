import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:clinic_go/core/di/service_locator.dart';
import 'package:clinic_go/features/medication/data/monthly_summary_repository.dart';
import 'package:clinic_go/features/medication/models/monthly_medication_log.dart';

enum DailyAdherenceStatus { allTaken, partial, missed }

class MonthlySummary {
  const MonthlySummary({required this.logs, required this.logsByDay});

  final List<MonthlyMedicationLog> logs;
  final Map<int, List<MonthlyMedicationLog>> logsByDay;

  int? get adherencePercentage {
    if (logs.isEmpty) {
      return null;
    }

    final taken = logs.where((log) => log.wasTaken).length;
    return ((taken / logs.length) * 100).round();
  }

  DailyAdherenceStatus? statusForDay(int day) {
    final dayLogs = logsByDay[day];
    if (dayLogs == null || dayLogs.isEmpty) {
      return null;
    }

    final takenCount = dayLogs.where((log) => log.wasTaken).length;
    if (takenCount == dayLogs.length) {
      return DailyAdherenceStatus.allTaken;
    }
    if (takenCount == 0) {
      return DailyAdherenceStatus.missed;
    }
    return DailyAdherenceStatus.partial;
  }
}

class SelectedMonthNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  void setMonth(DateTime month) {
    state = DateTime(month.year, month.month);
  }
}

final selectedMonthProvider = NotifierProvider<SelectedMonthNotifier, DateTime>(
  SelectedMonthNotifier.new,
);

final monthlySummaryRepositoryProvider = Provider<MonthlySummaryRepository>((
  ref,
) {
  return MonthlySummaryRepository(getIt<SupabaseClient>());
});

final monthlyLogsProvider = FutureProvider.family<MonthlySummary, DateTime>((
  ref,
  month,
) async {
  final normalizedMonth = DateTime(month.year, month.month);
  final repository = ref.watch(monthlySummaryRepositoryProvider);
  final logs = await repository.fetchMonthlyLogs(normalizedMonth);
  final logsByDay = <int, List<MonthlyMedicationLog>>{};

  for (final log in logs) {
    logsByDay.putIfAbsent(log.takenAt.day, () => []).add(log);
  }

  return MonthlySummary(logs: logs, logsByDay: logsByDay);
});
