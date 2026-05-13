import 'dart:async';

import 'package:clinic_go/features/symptoms/data/symptom_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ── Mocktail mocks ───────────────────────────────────────────────────────────

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

// ── Helpers ──────────────────────────────────────────────────────────────────

const _validLogRow = <String, dynamic>{
  'id': 'log-1',
  'user_id': 'user-1',
  'symptom_id': 'symptom-1',
  'custom_symptom': null,
  'symptoms': {'name': 'headache'},
  'severity': 5,
  'notes': null,
  'occurred_at': '2026-05-01T08:00:00.000Z',
  'created_at': '2026-05-01T08:05:00.000Z',
};

void stubSymptomLookup(
  MockSupabaseClient mockClient,
  List<Map<String, dynamic>> rows,
) {
  final symptomsBuilder = FakeQueryBuilder();
  final symptomsFilterBuilder = FakeFilterBuilder<PostgrestList>(
    () => Future.value(rows),
  );

  when(() => mockClient.from('symptoms')).thenAnswer((_) => symptomsBuilder);
  when(
    () => symptomsBuilder.select('id'),
  ).thenAnswer((_) => symptomsFilterBuilder);
  when(
    () => symptomsFilterBuilder.eq('name', any()),
  ).thenAnswer((_) => symptomsFilterBuilder);
  when(
    () => symptomsFilterBuilder.limit(1),
  ).thenAnswer((_) => symptomsFilterBuilder);
}

void main() {
  late SymptomRepository repository;
  late MockSupabaseClient mockClient;
  late MockGoTrueClient mockAuth;
  late MockUser mockUser;

  setUpAll(() {
    registerFallbackValue(const <String, dynamic>{});
  });

  setUp(() {
    mockClient = MockSupabaseClient();
    mockAuth = MockGoTrueClient();
    mockUser = MockUser();

    when(() => mockClient.auth).thenReturn(mockAuth);
    when(() => mockUser.id).thenReturn('user-1');

    repository = SymptomRepository(mockClient);
  });

  // ── insertSymptomLog ────────────────────────────────────────────────────────

  group('SymptomRepository.insertSymptomLog', () {
    test('Happy path: calls insert without throwing', () async {
      stubSymptomLookup(mockClient, [
        {'id': 'symptom-1'},
      ]);
      final queryBuilder = FakeQueryBuilder();
      final filterBuilder = FakeFilterBuilder<PostgrestList>(
        () => Future.value([]),
      );

      when(
        () => mockClient.from('symptom_logs'),
      ).thenAnswer((_) => queryBuilder);
      when(
        () => queryBuilder.insert(any<Map<String, dynamic>>()),
      ).thenAnswer((_) => filterBuilder);

      await expectLater(
        repository.insertSymptomLog(
          userId: 'user-1',
          symptomType: 'headache',
          severity: 5,
          notes: 'Mild',
          occurredAt: DateTime(2026, 5, 13, 8),
        ),
        completes,
      );
    });

    test('Empty notes string is saved as null', () async {
      stubSymptomLookup(mockClient, [
        {'id': 'symptom-2'},
      ]);
      final queryBuilder = FakeQueryBuilder();
      Map<String, dynamic>? capturedPayload;

      final filterBuilder = FakeFilterBuilder<PostgrestList>(
        () => Future.value([]),
      );

      when(
        () => mockClient.from('symptom_logs'),
      ).thenAnswer((_) => queryBuilder);
      when(() => queryBuilder.insert(any<Map<String, dynamic>>())).thenAnswer((
        invocation,
      ) {
        capturedPayload =
            invocation.positionalArguments.first as Map<String, dynamic>;
        return filterBuilder;
      });

      await repository.insertSymptomLog(
        userId: 'user-1',
        symptomType: 'nausea',
        severity: 3,
        notes: '   ',
        occurredAt: DateTime(2026, 5, 13),
      );

      expect(capturedPayload!['notes'], isNull);
      expect(capturedPayload!['symptom_id'], 'symptom-2');
      expect(capturedPayload!['custom_symptom'], isNull);
    });

    test('Network failure: rethrows PostgrestException', () async {
      stubSymptomLookup(mockClient, [
        {'id': 'symptom-1'},
      ]);
      final queryBuilder = FakeQueryBuilder();
      final filterBuilder = FakeFilterBuilder<PostgrestList>(
        () => Future.error(const PostgrestException(message: 'Network error')),
      );

      when(
        () => mockClient.from('symptom_logs'),
      ).thenAnswer((_) => queryBuilder);
      when(
        () => queryBuilder.insert(any<Map<String, dynamic>>()),
      ).thenAnswer((_) => filterBuilder);

      expect(
        () => repository.insertSymptomLog(
          userId: 'user-1',
          symptomType: 'headache',
          severity: 5,
          occurredAt: DateTime(2026, 5, 13),
        ),
        throwsA(isA<PostgrestException>()),
      );
    });
  });

  // ── fetchSymptomLogs ────────────────────────────────────────────────────────

  group('SymptomRepository.fetchSymptomLogs', () {
    test('Returns empty list when no user is signed in', () async {
      when(() => mockAuth.currentUser).thenReturn(null);

      final result = await repository.fetchSymptomLogs();
      expect(result, isEmpty);
    });

    test('Happy path: parses and returns log list', () async {
      when(() => mockAuth.currentUser).thenReturn(mockUser);

      final queryBuilder = FakeQueryBuilder();
      final filterBuilder = FakeFilterBuilder<PostgrestList>(
        () => Future.value([_validLogRow]),
      );

      when(
        () => mockClient.from('symptom_logs'),
      ).thenAnswer((_) => queryBuilder);
      when(
        () => queryBuilder.select('*, symptoms(name)'),
      ).thenAnswer((_) => filterBuilder);
      when(
        () => filterBuilder.eq('user_id', 'user-1'),
      ).thenAnswer((_) => filterBuilder);
      when(
        () => filterBuilder.order('occurred_at', ascending: false),
      ).thenAnswer((_) => filterBuilder);

      final result = await repository.fetchSymptomLogs();
      expect(result.length, 1);
      expect(result.first.id, 'log-1');
      expect(result.first.symptomType, 'headache');
      expect(result.first.severity, 5);
    });

    test('Returns empty list when database returns no rows', () async {
      when(() => mockAuth.currentUser).thenReturn(mockUser);

      final queryBuilder = FakeQueryBuilder();
      final filterBuilder = FakeFilterBuilder<PostgrestList>(
        () => Future.value([]),
      );

      when(
        () => mockClient.from('symptom_logs'),
      ).thenAnswer((_) => queryBuilder);
      when(
        () => queryBuilder.select('*, symptoms(name)'),
      ).thenAnswer((_) => filterBuilder);
      when(
        () => filterBuilder.eq('user_id', 'user-1'),
      ).thenAnswer((_) => filterBuilder);
      when(
        () => filterBuilder.order('occurred_at', ascending: false),
      ).thenAnswer((_) => filterBuilder);

      final result = await repository.fetchSymptomLogs();
      expect(result, isEmpty);
    });

    test('Network failure: throws PostgrestException', () async {
      when(() => mockAuth.currentUser).thenReturn(mockUser);

      final queryBuilder = FakeQueryBuilder();
      final filterBuilder = FakeFilterBuilder<PostgrestList>(
        () => Future.error(const PostgrestException(message: 'Fetch failed')),
      );

      when(
        () => mockClient.from('symptom_logs'),
      ).thenAnswer((_) => queryBuilder);
      when(
        () => queryBuilder.select('*, symptoms(name)'),
      ).thenAnswer((_) => filterBuilder);
      when(
        () => filterBuilder.eq('user_id', 'user-1'),
      ).thenAnswer((_) => filterBuilder);
      when(
        () => filterBuilder.order('occurred_at', ascending: false),
      ).thenAnswer((_) => filterBuilder);

      expect(
        () => repository.fetchSymptomLogs(),
        throwsA(isA<PostgrestException>()),
      );
    });

    test('Malformed row: throws when required field is missing', () async {
      when(() => mockAuth.currentUser).thenReturn(mockUser);

      final queryBuilder = FakeQueryBuilder();
      final filterBuilder = FakeFilterBuilder<PostgrestList>(
        () => Future.value([
          <String, dynamic>{'bad': 'data'},
        ]),
      );

      when(
        () => mockClient.from('symptom_logs'),
      ).thenAnswer((_) => queryBuilder);
      when(
        () => queryBuilder.select('*, symptoms(name)'),
      ).thenAnswer((_) => filterBuilder);
      when(
        () => filterBuilder.eq('user_id', 'user-1'),
      ).thenAnswer((_) => filterBuilder);
      when(
        () => filterBuilder.order('occurred_at', ascending: false),
      ).thenAnswer((_) => filterBuilder);

      expect(() => repository.fetchSymptomLogs(), throwsA(isA<TypeError>()));
    });
  });
}
