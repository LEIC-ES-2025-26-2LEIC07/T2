import 'dart:async';

import 'package:clinic_go/features/calendar/data/calendar_repository.dart';
import 'package:clinic_go/features/calendar/presentation/view_models/calendar_view_model.dart';
import 'package:clinic_go/features/calendar/presentation/views/calendar_screen.dart';
import 'package:clinic_go/features/medication/data/dose_log_repository.dart';
import 'package:clinic_go/features/medication/data/medication_repository.dart';
import 'package:clinic_go/features/medication/models/medication.dart';
import 'package:clinic_go/features/medication/models/medication_reminder.dart';
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
  Future<void> editMedication(EditMedicationPayload payload) async {}
  @override
  Future<void> deleteMedication(String id) async {}
  @override
  Future<List<MedicationReminder>> fetchRemindersForMedication(
    String medicationId,
  ) async => [];
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

Widget _wrap(CalendarViewModel vm) => MaterialApp(
  theme: ThemeData(splashFactory: NoSplash.splashFactory),
  home: CalendarScreen(viewModel: vm),
);

DoseLogEntry _entry({
  required DateTime scheduledTime,
  DoseLogStatus status = DoseLogStatus.taken,
  String medicationName = 'Aspirin',
}) => DoseLogEntry(
  id: 'log-1',
  status: status,
  scheduledTime: scheduledTime,
  takenTime: scheduledTime,
  medicationId: 'med-1',
  medicationName: medicationName,
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
    testWidgets('displays PLANO title', (tester) async {
      final vm = await _loadedVM();
      await tester.pumpWidget(_wrap(vm));
      await tester.pump();

      expect(find.text('PLANO'), findsOneWidget);
    });

    testWidgets('displays the formatted month header in Portuguese', (
      tester,
    ) async {
      final vm = await _loadedVM();
      await tester.pumpWidget(_wrap(vm));
      await tester.pump();

      expect(find.text('MAI 2026'), findsOneWidget);
    });

    testWidgets('displays all four legend labels', (tester) async {
      final vm = await _loadedVM();
      await tester.pumpWidget(_wrap(vm));
      await tester.pump();

      expect(find.text('Todas tomadas'), findsOneWidget);
      expect(find.text('Parcial'), findsOneWidget);
      expect(find.text('Falhadas'), findsOneWidget);
      expect(find.text('Próximas'), findsOneWidget);
    });

    testWidgets('displays weekday row headers', (tester) async {
      final vm = await _loadedVM();
      await tester.pumpWidget(_wrap(vm));
      await tester.pump();

      expect(find.text('SEG'), findsOneWidget);
      expect(find.text('DOM'), findsOneWidget);
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
  });

  group('CalendarScreen – doses panel', () {
    testWidgets('shows "Sem doses" for a day with no activity', (tester) async {
      final vm = await _loadedVM();
      await tester.pumpWidget(_wrap(vm));
      await tester.pump();

      await tester.tap(find.text('3'));
      await tester.pumpAndSettle();

      expect(find.text('Sem doses para este dia.'), findsOneWidget);
    });

    testWidgets('shows medication name in panel after tapping a logged day', (
      tester,
    ) async {
      final vm = await _loadedVM(
        logs: [_entry(scheduledTime: DateTime(2026, 5, 8, 9))],
      );
      await tester.pumpWidget(_wrap(vm));
      await tester.pump();

      await tester.tap(find.text('8'));
      await tester.pumpAndSettle();

      expect(find.text('Aspirin'), findsOneWidget);
    });

    testWidgets('shows "tomada" status badge for a taken dose', (tester) async {
      final vm = await _loadedVM(
        logs: [
          _entry(
            scheduledTime: DateTime(2026, 5, 8, 9),
            status: DoseLogStatus.taken,
          ),
        ],
      );
      await tester.pumpWidget(_wrap(vm));
      await tester.pump();

      await tester.tap(find.text('8'));
      await tester.pumpAndSettle();

      expect(find.text('tomada'), findsOneWidget);
    });

    testWidgets('shows "falhada" status badge for a skipped dose', (
      tester,
    ) async {
      final vm = await _loadedVM(
        logs: [
          _entry(
            scheduledTime: DateTime(2026, 5, 8, 9),
            status: DoseLogStatus.skipped,
          ),
        ],
      );
      await tester.pumpWidget(_wrap(vm));
      await tester.pump();

      await tester.tap(find.text('8'));
      await tester.pumpAndSettle();

      expect(find.text('falhada'), findsOneWidget);
    });
  });

  group('CalendarScreen – navigation buttons', () {
    testWidgets('chevron_right advances to JUN 2026', (tester) async {
      final vm = await _loadedVM();
      await tester.pumpWidget(_wrap(vm));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pumpAndSettle();

      expect(find.text('JUN 2026'), findsOneWidget);
    });

    testWidgets('chevron_left goes back to ABR 2026', (tester) async {
      final vm = await _loadedVM();
      await tester.pumpWidget(_wrap(vm));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pumpAndSettle();

      expect(find.text('ABR 2026'), findsOneWidget);
    });
  });
}
