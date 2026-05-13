import 'package:flutter_test/flutter_test.dart';
import 'package:clinic_go/features/medication/models/monthly_medication_log.dart';
import 'package:clinic_go/features/medication/presentation/view_models/monthly_summary_providers.dart';

MonthlyMedicationLog _log({
  required String id,
  required int day,
  required bool wasTaken,
}) {
  return MonthlyMedicationLog(
    id: id,
    takenAt: DateTime(2026, 5, day, 8),
    wasTaken: wasTaken,
    medicationName: 'Aspirin',
    dosage: '100mg',
  );
}

void main() {
  group('MonthlySummary', () {
    test('calculates adherence percentage from taken vs total logs', () {
      final logs = [
        _log(id: '1', day: 1, wasTaken: true),
        _log(id: '2', day: 1, wasTaken: false),
        _log(id: '3', day: 2, wasTaken: true),
      ];

      final summary = MonthlySummary(logs: logs, logsByDay: const {});

      expect(summary.adherencePercentage, 67);
    });

    test('returns null adherence percentage when there are no logs', () {
      const summary = MonthlySummary(logs: [], logsByDay: {});

      expect(summary.adherencePercentage, isNull);
    });

    test('resolves daily adherence statuses', () {
      final dayOneLogs = [
        _log(id: '1', day: 1, wasTaken: true),
        _log(id: '2', day: 1, wasTaken: true),
      ];
      final dayTwoLogs = [
        _log(id: '3', day: 2, wasTaken: true),
        _log(id: '4', day: 2, wasTaken: false),
      ];
      final dayThreeLogs = [
        _log(id: '5', day: 3, wasTaken: false),
        _log(id: '6', day: 3, wasTaken: false),
      ];

      final summary = MonthlySummary(
        logs: [...dayOneLogs, ...dayTwoLogs, ...dayThreeLogs],
        logsByDay: {1: dayOneLogs, 2: dayTwoLogs, 3: dayThreeLogs},
      );

      expect(summary.statusForDay(1), DailyAdherenceStatus.allTaken);
      expect(summary.statusForDay(2), DailyAdherenceStatus.partial);
      expect(summary.statusForDay(3), DailyAdherenceStatus.missed);
      expect(summary.statusForDay(4), isNull);
    });
  });
}
