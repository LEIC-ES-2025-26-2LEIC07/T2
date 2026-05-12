import 'package:flutter/foundation.dart';

import 'package:clinic_go/features/medication/data/calendar_repository.dart';
import 'package:clinic_go/features/medication/models/scheduled_dose.dart';
import 'package:clinic_go/features/medication/data/medication_repository.dart';
import 'package:clinic_go/features/medication/services/dose_scheduling_service.dart';
import 'package:clinic_go/features/medication/data/dose_log_repository.dart';

enum DaySummaryStatus { none, allTaken, partial, missed, upcoming }

class DaySummary {
  DaySummary({required this.date});

  final DateTime date;
  final List<DoseLogEntry> logs = [];
  final List<ScheduledDose> scheduled = [];

  DaySummaryStatus get status {
    if (logs.isEmpty && scheduled.isEmpty) return DaySummaryStatus.none;

    final taken = logs.where((l) => l.status == DoseLogStatus.taken).length;
    final totalScheduled = scheduled.length + logs.length;

    if (totalScheduled == 0) return DaySummaryStatus.none;

    if (taken == totalScheduled) return DaySummaryStatus.allTaken;
    if (taken > 0) return DaySummaryStatus.partial;

    // none taken
    final now = DateTime.now();
    if (date.isBefore(DateTime(now.year, now.month, now.day))) {
      return DaySummaryStatus.missed;
    }
    return DaySummaryStatus.upcoming;
  }
}

class CalendarViewModel extends ChangeNotifier {
  CalendarViewModel({
    required this.calendarRepository,
    required this.medRepository,
    required this.schedulingService,
  });

  final CalendarRepository calendarRepository;
  final MedicationRepository medRepository;
  final DoseSchedulingService schedulingService;

  bool _isLoading = false;
  String? _error;
  DateTime _currentMonth = DateTime.now();

  final Map<String, DaySummary> _cache = {};

  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime get currentMonth => _currentMonth;

  List<DaySummary> get summaries {
    final year = _currentMonth.year;
    final month = _currentMonth.month;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final out = <DaySummary>[];
    for (var d = 1; d <= daysInMonth; d++) {
      final dt = DateTime(year, month, d);
      final key = _keyFor(dt);
      out.add(_cache[key] ?? DaySummary(date: dt));
    }
    return out;
  }

  Future<void> loadMonth(DateTime month) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    _currentMonth = DateTime(month.year, month.month, 1);

    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

    try {
      final logs = await calendarRepository.fetchDoseLogs(from: start, to: end);

      // scheduled doses from reminders
      final meds = await medRepository.fetchMedications();
      final reminders = await medRepository.fetchAllReminders();

      final scheduled = <ScheduledDose>[];
      for (final med in meds) {
        final medReminders = reminders
            .where((r) => r.medicationId == med.id)
            .toList();
        scheduled.addAll(
          schedulingService.calculateUpcomingDoses(
            med,
            medReminders,
            from: start,
            duration: end.difference(start) + const Duration(days: 1),
          ),
        );
      }

      // group by day
      final Map<String, DaySummary> map = {};

      DaySummary ensure(DateTime d) {
        final key = _keyFor(d);
        return map.putIfAbsent(
          key,
          () => DaySummary(date: DateTime(d.year, d.month, d.day)),
        );
      }

      for (final s in scheduled) {
        final day = DateTime(
          s.scheduledTime.year,
          s.scheduledTime.month,
          s.scheduledTime.day,
        );
        ensure(day).scheduled.add(s);
      }

      for (final l in logs) {
        final day = DateTime(
          l.scheduledTime.year,
          l.scheduledTime.month,
          l.scheduledTime.day,
        );
        ensure(day).logs.add(l);
      }

      // fill cache for month days
      final daysInMonth = DateTime(start.year, start.month + 1, 0).day;
      for (var d = 1; d <= daysInMonth; d++) {
        final dt = DateTime(start.year, start.month, d);
        final key = _keyFor(dt);
        _cache[key] = map[key] ?? DaySummary(date: dt);
      }
    } catch (e) {
      _error = 'Failed to load calendar data: ${e.toString()}';
      debugPrint('CalendarViewModel.loadMonth error: $e');
      debugPrintStack();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void goToNextMonth() {
    final next = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    loadMonth(next);
  }

  void goToPreviousMonth() {
    final prev = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    loadMonth(prev);
  }

  DaySummary? daySummaryFor(DateTime day) => _cache[_keyFor(day)];

  String _keyFor(DateTime d) => '${d.year}-${d.month}-${d.day}';
}
