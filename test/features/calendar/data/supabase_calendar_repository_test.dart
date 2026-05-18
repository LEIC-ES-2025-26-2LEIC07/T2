import 'dart:async';

import 'package:clinic_go/features/calendar/data/supabase_calendar_repository.dart';
import 'package:clinic_go/features/medication/data/dose_log_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockUser extends Mock implements User {}

class FakeQueryBuilder extends Mock implements SupabaseQueryBuilder {}

class FakeFilterBuilder<T> extends Mock implements PostgrestFilterBuilder<T> {
  FakeFilterBuilder(this._futureFn);
  final Future<T> Function() _futureFn;

  @override
  Future<R> then<R>(
    FutureOr<R> Function(T value) onValue, {
    Function? onError,
  }) => _futureFn().then(onValue, onError: onError);
}

// ── Helpers ───────────────────────────────────────────────────────────────────

/// Builds a chained [FakeFilterBuilder] whose filter methods (gte, lte, filter)
/// all return the same instance so the fluent call-chain resolves correctly.
FakeFilterBuilder<PostgrestList> _chainedFilter(
  Future<PostgrestList> Function() fn,
) {
  final fb = FakeFilterBuilder<PostgrestList>(fn);
  when(() => fb.gte(any(), any())).thenAnswer((_) => fb);
  when(() => fb.lte(any(), any())).thenAnswer((_) => fb);
  when(() => fb.filter(any(), any(), any())).thenAnswer((_) => fb);
  return fb;
}

/// Wires a standard three-table query chain for a single-log scenario.
void _stubFullChain({
  required MockSupabaseClient client,
  required List<Map<String, dynamic>> logs,
  required List<Map<String, dynamic>> reminders,
  required List<Map<String, dynamic>> medications,
}) {
  final logsQB = FakeQueryBuilder();
  final logsFilter = _chainedFilter(() => Future.value(logs));
  when(() => client.from('medication_logs')).thenAnswer((_) => logsQB);
  when(
    () => logsQB.select('id, reminder_id, taken_at, was_taken'),
  ).thenAnswer((_) => logsFilter);

  final remsQB = FakeQueryBuilder();
  final remsFilter = _chainedFilter(() => Future.value(reminders));
  when(() => client.from('medication_reminders')).thenAnswer((_) => remsQB);
  when(() => remsQB.select('id, medication_id')).thenAnswer((_) => remsFilter);

  final medsQB = FakeQueryBuilder();
  final medsFilter = _chainedFilter(() => Future.value(medications));
  when(() => client.from('medications')).thenAnswer((_) => medsQB);
  when(() => medsQB.select('id, name, dosage')).thenAnswer((_) => medsFilter);
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late SupabaseCalendarRepository repository;
  late MockSupabaseClient mockClient;
  late MockGoTrueClient mockAuth;
  late MockUser mockUser;

  setUpAll(() {
    registerFallbackValue('');
  });

  setUp(() {
    mockClient = MockSupabaseClient();
    mockAuth = MockGoTrueClient();
    mockUser = MockUser();

    when(() => mockClient.auth).thenReturn(mockAuth);
    when(() => mockUser.id).thenReturn('user-123');

    repository = SupabaseCalendarRepository(mockClient);
  });

  final from = DateTime(2026, 5, 1);
  final to = DateTime(2026, 5, 31, 23, 59, 59);

  group('SupabaseCalendarRepository.fetchDoseLogs', () {
    test('throws StateError when no user is authenticated', () async {
      when(() => mockAuth.currentUser).thenReturn(null);

      expect(
        () => repository.fetchDoseLogs(from: from, to: to),
        throwsA(isA<StateError>()),
      );
    });

    test('returns empty list when there are no logs in range', () async {
      when(() => mockAuth.currentUser).thenReturn(mockUser);

      final logsQB = FakeQueryBuilder();
      final logsFilter = _chainedFilter(
        () => Future.value(<Map<String, dynamic>>[]),
      );
      when(() => mockClient.from('medication_logs')).thenAnswer((_) => logsQB);
      when(
        () => logsQB.select('id, reminder_id, taken_at, was_taken'),
      ).thenAnswer((_) => logsFilter);

      final result = await repository.fetchDoseLogs(from: from, to: to);
      expect(result, isEmpty);
    });

    test(
      'returns empty list when logs reference medications not owned by user',
      () async {
        when(() => mockAuth.currentUser).thenReturn(mockUser);

        _stubFullChain(
          client: mockClient,
          logs: [
            {
              'id': 'log-1',
              'reminder_id': 'rem-1',
              'taken_at': DateTime(2026, 5, 10, 9).toIso8601String(),
              'was_taken': true,
            },
          ],
          reminders: [
            {'id': 'rem-1', 'medication_id': 'med-1'},
          ],
          // Empty: RLS filtered out the medication (not owned by current user)
          medications: [],
        );

        final result = await repository.fetchDoseLogs(from: from, to: to);
        expect(result, isEmpty);
      },
    );

    test('maps a taken log to a DoseLogEntry with correct fields', () async {
      when(() => mockAuth.currentUser).thenReturn(mockUser);

      final takenAt = DateTime(2026, 5, 10, 9);
      _stubFullChain(
        client: mockClient,
        logs: [
          {
            'id': 'log-1',
            'reminder_id': 'rem-1',
            'taken_at': takenAt.toIso8601String(),
            'was_taken': true,
          },
        ],
        reminders: [
          {'id': 'rem-1', 'medication_id': 'med-1'},
        ],
        medications: [
          {'id': 'med-1', 'name': 'Aspirin', 'dosage': '100mg'},
        ],
      );

      final result = await repository.fetchDoseLogs(from: from, to: to);

      expect(result.length, 1);
      final entry = result.first;
      expect(entry.id, 'log-1');
      expect(entry.medicationName, 'Aspirin');
      expect(entry.dosage, '100mg');
      expect(entry.status, DoseLogStatus.taken);
      expect(entry.takenTime, takenAt);
    });

    test('maps a skipped log to DoseLogEntry with skipped status', () async {
      when(() => mockAuth.currentUser).thenReturn(mockUser);

      final takenAt = DateTime(2026, 5, 12, 8);
      _stubFullChain(
        client: mockClient,
        logs: [
          {
            'id': 'log-2',
            'reminder_id': 'rem-1',
            'taken_at': takenAt.toIso8601String(),
            'was_taken': false,
          },
        ],
        reminders: [
          {'id': 'rem-1', 'medication_id': 'med-1'},
        ],
        medications: [
          {'id': 'med-1', 'name': 'Lisinopril', 'dosage': '5mg'},
        ],
      );

      final result = await repository.fetchDoseLogs(from: from, to: to);

      expect(result.length, 1);
      expect(result.first.status, DoseLogStatus.skipped);
    });

    test('throws when the medication_logs query fails', () async {
      when(() => mockAuth.currentUser).thenReturn(mockUser);

      final logsQB = FakeQueryBuilder();
      final logsFilter = _chainedFilter(
        () => Future.error(const PostgrestException(message: 'DB error')),
      );
      when(() => mockClient.from('medication_logs')).thenAnswer((_) => logsQB);
      when(
        () => logsQB.select('id, reminder_id, taken_at, was_taken'),
      ).thenAnswer((_) => logsFilter);

      // debugPrintStack inside the repo's catch block cannot parse
      // stack_trace-style frames in the Flutter test environment, so we
      // verify via try/catch rather than throwsA.
      bool threw = false;
      try {
        await repository.fetchDoseLogs(from: from, to: to);
      } catch (_) {
        threw = true;
      }
      expect(threw, isTrue);
    });
  });
}
