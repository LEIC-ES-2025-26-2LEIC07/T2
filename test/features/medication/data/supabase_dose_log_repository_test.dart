// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:clinic_go/features/medication/data/supabase_dose_log_repository.dart';
import 'package:clinic_go/features/medication/data/dose_log_repository.dart';
import 'package:clinic_go/features/medication/models/scheduled_dose.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockUser extends Mock implements User {}

class FakeQueryBuilder extends Mock implements SupabaseQueryBuilder {}

class FakeFilterBuilder<T> extends Mock implements PostgrestFilterBuilder<T> {
  final Future<T> Function() _futureFn;
  FakeFilterBuilder(this._futureFn);

  @override
  Future<R> then<R>(
    FutureOr<R> Function(T value) onValue, {
    Function? onError,
  }) =>
      _futureFn().then(onValue, onError: onError);
}

// doseId format: '<reminderId>_<epochSeconds>'
const _validDoseId = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890_1713254400';

final _demoScheduledDose = ScheduledDose(
  id: _validDoseId,
  medicationId: 'med-1',
  medicationName: 'Aspirin',
  dosage: '100mg',
  scheduledTime: DateTime.fromMillisecondsSinceEpoch(1713254400 * 1000),
);

void main() {
  late SupabaseDoseLogRepository repository;
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
    when(() => mockUser.id).thenReturn('user-123');

    repository = SupabaseDoseLogRepository(mockClient);
  });

  group('SupabaseDoseLogRepository', () {
    group('insertDoseLog', () {
      test('insertDoseLog: happy path → inserts without error', () async {
        final queryBuilder = FakeQueryBuilder();
        final filterBuilder = FakeFilterBuilder<PostgrestList>(
          () => Future.value([]),
        );

        when(
          () => mockClient.from('medication_logs'),
        ).thenAnswer((_) => queryBuilder);
        when(
          () => queryBuilder.insert(any<Map<String, dynamic>>()),
        ).thenAnswer((_) => filterBuilder);

        await expectLater(
          repository.insertDoseLog(
            dose: _demoScheduledDose,
            status: DoseLogStatus.taken,
            loggedAt: DateTime(2026, 4, 16, 8),
          ),
          completes,
        );
      });

      test(
        'insertDoseLog: network failure → throws PostgrestException',
        () async {
          final queryBuilder = FakeQueryBuilder();
          final filterBuilder = FakeFilterBuilder<PostgrestList>(
            () => Future.error(
              const PostgrestException(message: 'Network error'),
            ),
          );

          when(
            () => mockClient.from('medication_logs'),
          ).thenAnswer((_) => queryBuilder);
          when(
            () => queryBuilder.insert(any<Map<String, dynamic>>()),
          ).thenAnswer((_) => filterBuilder);

          expect(
            () => repository.insertDoseLog(
              dose: _demoScheduledDose,
              status: DoseLogStatus.skipped,
              loggedAt: DateTime(2026, 4, 16, 8),
            ),
            throwsA(isA<PostgrestException>()),
          );
        },
      );
    });

    group('hasDoseLog', () {
      FakeFilterBuilder<PostgrestList> _buildChainedFilter(
        Future<PostgrestList> Function() futureFn,
      ) {
        final filterBuilder = FakeFilterBuilder<PostgrestList>(futureFn);
        when(
          () => filterBuilder.eq(any(), any()),
        ).thenAnswer((_) => filterBuilder);
        when(
          () => filterBuilder.gte(any(), any()),
        ).thenAnswer((_) => filterBuilder);
        when(
          () => filterBuilder.lt(any(), any()),
        ).thenAnswer((_) => filterBuilder);
        when(
          () => filterBuilder.limit(any()),
        ).thenAnswer((_) => filterBuilder);
        return filterBuilder;
      }

      test('hasDoseLog: log exists → returns true', () async {
        when(() => mockAuth.currentUser).thenReturn(mockUser);

        final queryBuilder = FakeQueryBuilder();
        final filterBuilder = _buildChainedFilter(
          () => Future.value([
            <String, dynamic>{'id': 'log-1'},
          ]),
        );

        when(
          () => mockClient.from('medication_logs'),
        ).thenAnswer((_) => queryBuilder);
        when(
          () => queryBuilder.select('id'),
        ).thenAnswer((_) => filterBuilder);

        final result = await repository.hasDoseLog(_validDoseId);
        expect(result, isTrue);
      });

      test(
        'hasDoseLog: no user logged in → returns false immediately',
        () async {
          when(() => mockAuth.currentUser).thenReturn(null);

          final result = await repository.hasDoseLog(_validDoseId);
          expect(result, isFalse);
          verifyNever(() => mockClient.from(any()));
        },
      );

      test('hasDoseLog: empty result → returns false', () async {
        when(() => mockAuth.currentUser).thenReturn(mockUser);

        final queryBuilder = FakeQueryBuilder();
        final filterBuilder = _buildChainedFilter(
          () => Future.value([]),
        );

        when(
          () => mockClient.from('medication_logs'),
        ).thenAnswer((_) => queryBuilder);
        when(
          () => queryBuilder.select('id'),
        ).thenAnswer((_) => filterBuilder);

        final result = await repository.hasDoseLog(_validDoseId);
        expect(result, isFalse);
      });

      test(
        'hasDoseLog: network failure → throws PostgrestException',
        () async {
          when(() => mockAuth.currentUser).thenReturn(mockUser);

          final queryBuilder = FakeQueryBuilder();
          final filterBuilder = _buildChainedFilter(
            () => Future.error(
              const PostgrestException(message: 'Network error'),
            ),
          );

          when(
            () => mockClient.from('medication_logs'),
          ).thenAnswer((_) => queryBuilder);
          when(
            () => queryBuilder.select('id'),
          ).thenAnswer((_) => filterBuilder);

          expect(
            () => repository.hasDoseLog(_validDoseId),
            throwsA(isA<PostgrestException>()),
          );
        },
      );
    });
  });
}
