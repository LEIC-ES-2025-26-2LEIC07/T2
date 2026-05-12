import 'dart:async';

import 'package:clinic_go/features/medication/data/calendar_repository.dart';
import 'package:clinic_go/features/medication/data/dose_log_repository.dart';
import 'package:clinic_go/features/medication/data/medication_repository.dart';
import 'package:clinic_go/features/medication/models/medication.dart';
import 'package:clinic_go/features/medication/models/medication_reminder.dart';
import 'package:clinic_go/features/medication/presentation/view_models/calendar_view_model.dart';
import 'package:clinic_go/features/medication/presentation/views/calendar_screen.dart';
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
  }) async => throw StateError('boom');
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
  @override
  Future<List<Medication>> fetchMedications() async => [];
  @override
  Future<List<MedicationReminder>> fetchAllReminders() async => [];
  @override
  Future<SavedMedicationResult> addMedication(AddMedicationPayload p) async =>
      const SavedMedicationResult(medicationId: '', reminders: []);
  @override
  Future<void> deleteMedication(String id) async {}
}

// ── Helpers ───────────────────────────────────────────────────────────────────

Future<CalendarViewModel> _loadedVM({
  List<DoseLogEntry> logs = const [],
  DateTime? month,
}) async {
  final vm = CalendarViewModel(
    calendarRepository: _FakeCalendarRepo(logs),
    medRepository: _FakeMedRepo(),
    schedulingService: const DoseSchedulingService(),
  );
  await vm.loadMonth(month ?? DateTime(2026, 5, 1));
  return vm;
}

Widget _wrap(CalendarViewModel vm) =>
    MaterialApp(home: CalendarScreen(viewModel: vm));

DoseLogEntry _entry({
  required DateTime scheduledTime,
  DoseLogStatus status = DoseLogStatus.taken,
}) => DoseLogEntry(
  id: 'log-1',
  status: status,
  scheduledTime: scheduledTime,
  takenTime: scheduledTime,
  medicationId: 'med-1',
  medicationName: 'Aspirin',
  dosage: '100mg',
);

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('CalendarScreen – loading state', () {
    testWidgets('shows CircularProgressIndicator while loading', (
      tester,
    ) async {
      final c = Completer<List<DoseLogEntry>>();
      final vm = CalendarViewModel(
        calendarRepository: _CompleterCalendarRepo(c),
        medRepository: _FakeMedRepo(),
        schedulingService: const DoseSchedulingService(),
      );
      vm.loadMonth(DateTime(2026, 5, 1));

      await tester.pumpWidget(_wrap(vm));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      c.complete([]);
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });

  group('CalendarScreen – error state', () {
    testWidgets('shows error message when repository throws', (tester) async {
      final vm = CalendarViewModel(
        calendarRepository: _ThrowingCalendarRepo(),
        medRepository: _FakeMedRepo(),
        schedulingService: const DoseSchedulingService(),
      );
      await vm.loadMonth(DateTime(2026, 5, 1));

      await tester.pumpWidget(_wrap(vm));
      await tester.pump();

      expect(find.textContaining('Failed to load calendar'), findsOneWidget);
    });
  });

  group('CalendarScreen – header and legend', () {
    testWidgets('displays the formatted month header', (tester) async {
      final vm = await _loadedVM();
      await tester.pumpWidget(_wrap(vm));
      await tester.pump();

      expect(find.text('May 2026'), findsOneWidget);
    });

    testWidgets('displays all four legend labels', (tester) async {
      final vm = await _loadedVM();
      await tester.pumpWidget(_wrap(vm));
      await tester.pump();

      expect(find.text('All taken'), findsOneWidget);
      expect(find.text('Partial'), findsOneWidget);
      expect(find.text('Missed'), findsOneWidget);
      expect(find.text('Upcoming'), findsOneWidget);
    });
  });

  group('CalendarScreen – day grid', () {
    testWidgets('renders the first and last day of May 2026', (tester) async {
      final vm = await _loadedVM();
      await tester.pumpWidget(_wrap(vm));
      await tester.pump();

      expect(find.text('1'), findsOneWidget);
      expect(find.text('31'), findsOneWidget);
      expect(find.text('32'), findsNothing);
    });

    testWidgets('shows check_circle icon on a day with all doses taken', (
      tester,
    ) async {
      final vm = await _loadedVM(
        logs: [_entry(scheduledTime: DateTime(2026, 5, 10, 9))],
      );
      await tester.pumpWidget(_wrap(vm));
      await tester.pump();

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });
  });

  group('CalendarScreen – day tap bottom sheet', () {
    testWidgets('shows "no activity" message for an empty day', (tester) async {
      final vm = await _loadedVM();
      await tester.pumpWidget(_wrap(vm));
      await tester.pump();

      await tester.tap(find.text('3'));
      await tester.pumpAndSettle();

      expect(find.text('No medication activity for this day.'), findsOneWidget);
    });

    testWidgets('shows log entry details in the bottom sheet', (tester) async {
      final logDay = DateTime(2026, 5, 8, 9);
      final vm = await _loadedVM(logs: [_entry(scheduledTime: logDay)]);
      await tester.pumpWidget(_wrap(vm));
      await tester.pump();

      await tester.tap(find.text('8'));
      await tester.pumpAndSettle();

      expect(find.text('Aspirin'), findsOneWidget);
      expect(find.textContaining('taken'), findsWidgets);
    });
  });

  group('CalendarScreen – navigation buttons', () {
    testWidgets('chevron_right advances to June 2026', (tester) async {
      final vm = await _loadedVM();
      await tester.pumpWidget(_wrap(vm));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pumpAndSettle();

      expect(find.text('June 2026'), findsOneWidget);
    });

    testWidgets('chevron_left goes back to April 2026', (tester) async {
      final vm = await _loadedVM();
      await tester.pumpWidget(_wrap(vm));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pumpAndSettle();

      expect(find.text('April 2026'), findsOneWidget);
    });
  });
}
