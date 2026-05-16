import 'dart:async';

import 'package:clinic_go/features/medication/data/calendar_repository.dart';
import 'package:clinic_go/features/medication/data/dose_log_repository.dart';
import 'package:clinic_go/features/medication/data/medication_repository.dart';
import 'package:clinic_go/features/medication/models/medication.dart';
import 'package:clinic_go/features/medication/models/medication_reminder.dart';
import 'package:clinic_go/features/medication/models/scheduled_dose.dart';
import 'package:clinic_go/features/medication/presentation/view_models/calendar_view_model.dart';
import 'package:clinic_go/features/medication/services/dose_scheduling_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ── Fakes ─────────────────────────────────────────────────────────────────────

class _FakeCalendarRepo implements CalendarRepository {
  _FakeCalendarRepo([this._entries = const []]);
  final List<DoseLogEntry> _entries;

  @override
  Future<List<DoseLogEntry>> fetchDoseLogs({
    required DateTime from,
    required DateTime to,
  }) async => _entries;
}

class _ThrowingCalendarRepo implements CalendarRepository {
  @override
  Future<List<DoseLogEntry>> fetchDoseLogs({
    required DateTime from,
    required DateTime to,
  }) async => throw StateError('network failure');
}

class _CompleterCalendarRepo implements CalendarRepository {
  _CompleterCalendarRepo(this._c);
  final Completer<List<DoseLogEntry>> _c;

  @override
  Future<List<DoseLogEntry>> fetchDoseLogs({
    required DateTime from,
    required DateTime to,
  }) => _c.future;
}

class _FakeMedRepo implements MedicationRepository {
  _FakeMedRepo({List<Medication>? meds, List<MedicationReminder>? reminders})
    : _meds = meds ?? [],
      _reminders = reminders ?? [];

  final List<Medication> _meds;
  final List<MedicationReminder> _reminders;

  @override
  Future<List<Medication>> fetchMedications() async => _meds;
  @override
  Future<List<MedicationReminder>> fetchAllReminders() async => _reminders;
  @override
  Future<SavedMedicationResult> addMedication(AddMedicationPayload p) async =>
      const SavedMedicationResult(medicationId: '', reminders: []);
  @override
  Future<void> editMedication(EditMedicationPayload payload) async {}
  @override
  Future<void> deleteMedication(String id) async {}
  @override
  Future<List<MedicationReminder>> fetchRemindersForMedication(
    String medicationId,
  ) async => [];
}

// ── Builders ──────────────────────────────────────────────────────────────────

CalendarViewModel _vm({
  CalendarRepository? calRepo,
  MedicationRepository? medRepo,
}) => CalendarViewModel(
  calendarRepository: calRepo ?? _FakeCalendarRepo(),
  medRepository: medRepo ?? _FakeMedRepo(),
  schedulingService: const DoseSchedulingService(),
);

DoseLogEntry _entry({
  required DateTime scheduledTime,
  DoseLogStatus status = DoseLogStatus.taken,
  String id = 'log-1',
}) => DoseLogEntry(
  id: id,
  status: status,
  scheduledTime: scheduledTime,
  takenTime: scheduledTime,
  medicationId: 'med-1',
  medicationName: 'Aspirin',
  dosage: '100mg',
);

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  final may2026 = DateTime(2026, 5, 1);

  // ── DaySummary.status ──────────────────────────────────────────────────────
  group('DaySummary.status', () {
    test('none when both lists are empty', () {
      expect(
        DaySummary(date: DateTime(2026, 5, 10)).status,
        DaySummaryStatus.none,
      );
    });

    test('allTaken when all logs are taken and no scheduled remain', () {
      final s = DaySummary(date: DateTime(2025, 1, 1));
      s.logs.add(_entry(scheduledTime: DateTime(2025, 1, 1, 9)));
      expect(s.status, DaySummaryStatus.allTaken);
    });

    test('partial when some logs taken and some skipped', () {
      final s = DaySummary(date: DateTime(2025, 1, 1));
      s.logs.add(_entry(scheduledTime: DateTime(2025, 1, 1, 9), id: 'l1'));
      s.logs.add(
        _entry(
          scheduledTime: DateTime(2025, 1, 1, 12),
          status: DoseLogStatus.skipped,
          id: 'l2',
        ),
      );
      expect(s.status, DaySummaryStatus.partial);
    });

    test(
      'partial when a taken log exists alongside pending scheduled doses',
      () {
        final s = DaySummary(date: DateTime(2025, 1, 1));
        s.logs.add(_entry(scheduledTime: DateTime(2025, 1, 1, 9)));
        s.scheduled.add(
          ScheduledDose(
            id: 'sd-1',
            medicationId: 'med-1',
            medicationName: 'Aspirin',
            dosage: '100mg',
            scheduledTime: DateTime(2025, 1, 1, 18),
          ),
        );
        expect(s.status, DaySummaryStatus.partial);
      },
    );

    test('missed when no doses taken on a past day', () {
      final past = DateTime(2000, 6, 15);
      final s = DaySummary(date: past);
      s.logs.add(_entry(scheduledTime: past, status: DoseLogStatus.skipped));
      expect(s.status, DaySummaryStatus.missed);
    });

    test('upcoming when no doses taken on a future day', () {
      final future = DateTime.now().add(const Duration(days: 10));
      final s = DaySummary(date: future);
      s.scheduled.add(
        ScheduledDose(
          id: 'sd-1',
          medicationId: 'med-1',
          medicationName: 'Aspirin',
          dosage: '100mg',
          scheduledTime: future,
        ),
      );
      expect(s.status, DaySummaryStatus.upcoming);
    });
  });

  // ── CalendarViewModel.loadMonth ────────────────────────────────────────────
  group('CalendarViewModel.loadMonth', () {
    test('returns 31 summaries for May 2026', () async {
      final vm = _vm();
      await vm.loadMonth(may2026);
      expect(vm.summaries.length, 31);
    });

    test('clears loading flag and error on success', () async {
      final vm = _vm();
      await vm.loadMonth(may2026);
      expect(vm.isLoading, isFalse);
      expect(vm.error, isNull);
    });

    test('maps a log entry to the correct day summary', () async {
      final logDay = DateTime(2026, 5, 15, 10);
      final vm = _vm(
        calRepo: _FakeCalendarRepo([_entry(scheduledTime: logDay)]),
      );
      await vm.loadMonth(may2026);

      final summary = vm.daySummaryFor(DateTime(2026, 5, 15));
      expect(summary, isNotNull);
      expect(summary!.logs.length, 1);
      expect(summary.logs.first.medicationName, 'Aspirin');
    });

    test('sets error message when repository throws', () async {
      final vm = _vm(calRepo: _ThrowingCalendarRepo());
      await vm.loadMonth(may2026);
      expect(vm.error, contains('Failed to load calendar'));
      expect(vm.isLoading, isFalse);
    });

    test('sets currentMonth to the first day of the requested month', () async {
      final vm = _vm();
      await vm.loadMonth(DateTime(2026, 8, 20));
      expect(vm.currentMonth, DateTime(2026, 8, 1));
    });

    test('transitions isLoading from true to false', () async {
      final states = <bool>[];
      final c = Completer<List<DoseLogEntry>>();
      final vm = _vm(calRepo: _CompleterCalendarRepo(c));
      vm.addListener(() => states.add(vm.isLoading));

      final loading = vm.loadMonth(may2026);
      expect(states, contains(true));

      c.complete([]);
      await loading;
      expect(states.last, isFalse);
    });

    test('uses scheduled doses from reminders in day summaries', () async {
      final med = Medication(
        id: 'med-1',
        userId: 'user-1',
        name: 'Lisinopril',
        dosageAmount: 5,
        dosageUnit: 'mg',
        color: Colors.blue,
        createdAt: DateTime(2026, 1, 1),
      );
      // Daily reminder at 08:00 covering every day of the week
      final allDays = const [
        'monday',
        'tuesday',
        'wednesday',
        'thursday',
        'friday',
        'saturday',
        'sunday',
      ];
      final reminder = MedicationReminder(
        id: 'rem-1',
        medicationId: 'med-1',
        reminderTime: '08:00:00',
        daysOfWeek: allDays,
      );

      final vm = _vm(
        medRepo: _FakeMedRepo(meds: [med], reminders: [reminder]),
      );
      await vm.loadMonth(may2026);

      // Every day in May should have a scheduled dose
      final day3 = vm.daySummaryFor(DateTime(2026, 5, 3));
      expect(day3, isNotNull);
      expect(day3!.scheduled, isNotEmpty);
    });
  });

  // ── Navigation ─────────────────────────────────────────────────────────────
  group('CalendarViewModel navigation', () {
    test('goToNextMonth advances currentMonth to June', () async {
      final vm = _vm();
      await vm.loadMonth(may2026);
      vm.goToNextMonth();
      expect(vm.currentMonth, DateTime(2026, 6, 1));
    });

    test('goToPreviousMonth steps currentMonth back to April', () async {
      final vm = _vm();
      await vm.loadMonth(may2026);
      vm.goToPreviousMonth();
      expect(vm.currentMonth, DateTime(2026, 4, 1));
    });

    test(
      'goToNextMonth wraps December into January of the following year',
      () async {
        final vm = _vm();
        await vm.loadMonth(DateTime(2026, 12, 1));
        vm.goToNextMonth();
        expect(vm.currentMonth, DateTime(2027, 1, 1));
      },
    );
  });

  // ── daySummaryFor ──────────────────────────────────────────────────────────
  group('CalendarViewModel.daySummaryFor', () {
    test('returns null before loadMonth is called', () {
      expect(_vm().daySummaryFor(DateTime(2026, 5, 10)), isNull);
    });

    test('returns a non-null summary after loadMonth', () async {
      final vm = _vm();
      await vm.loadMonth(may2026);
      expect(vm.daySummaryFor(DateTime(2026, 5, 10)), isNotNull);
    });

    test('returns null for a day outside the loaded month', () async {
      final vm = _vm();
      await vm.loadMonth(may2026);
      expect(vm.daySummaryFor(DateTime(2026, 6, 1)), isNull);
    });
  });
}
