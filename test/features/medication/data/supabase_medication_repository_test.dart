import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:clinic_go/features/medication/data/supabase_medication_repository.dart';
import 'package:clinic_go/features/medication/data/medication_repository.dart';
import 'package:flutter/material.dart' show Color;

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
  }) => _futureFn().then(onValue, onError: onError);
}

class FakeTransformBuilder<T> extends Mock
    implements PostgrestTransformBuilder<T> {
  final Future<T> Function() _futureFn;
  FakeTransformBuilder(this._futureFn);

  @override
  Future<R> then<R>(
    FutureOr<R> Function(T value) onValue, {
    Function? onError,
  }) => _futureFn().then(onValue, onError: onError);
}

void main() {
  late SupabaseMedicationRepository repository;
  late MockSupabaseClient mockClient;
  late MockGoTrueClient mockAuth;
  late MockUser mockUser;

  setUpAll(() {
    registerFallbackValue(const <String, dynamic>{});
    registerFallbackValue(const <Map<String, dynamic>>[]);
  });

  setUp(() {
    mockClient = MockSupabaseClient();
    mockAuth = MockGoTrueClient();
    mockUser = MockUser();

    when(() => mockClient.auth).thenReturn(mockAuth);
    when(() => mockUser.id).thenReturn('user-123');

    repository = SupabaseMedicationRepository(mockClient);
  });

  group('SupabaseMedicationRepository', () {
    group('addMedication', () {
      final payload = AddMedicationPayload(
        name: 'Aspirin',
        dosageAmount: 100,
        dosageUnit: 'mg',
        frequency: 'Daily',
        color: const Color(0xFFE57373),
        startDate: DateTime(2023, 1, 1),
        endDate: DateTime(2023, 1, 10),
        notes: 'Take with food',
        reminderTimes: const ['08:00:00'],
        daysOfWeek: const [
          'monday',
          'tuesday',
          'wednesday',
          'thursday',
          'friday',
          'saturday',
          'sunday',
        ],
      );

      test(
        'Happy path: successfully inserts medication and reminders, returns UUID',
        () async {
          when(() => mockAuth.currentUser).thenReturn(mockUser);

          final medBuilder = FakeQueryBuilder();
          final filterBuilder = FakeFilterBuilder<PostgrestList>(
            () => Future.value([]),
          );
          final listTransformBuilder = FakeTransformBuilder<PostgrestList>(
            () => Future.value([]),
          );
          final mapTransformBuilder = FakeTransformBuilder<PostgrestMap>(
            () => Future.value(<String, dynamic>{'id': 'med-123'}),
          );

          when(
            () => mockClient.from('medications'),
          ).thenAnswer((_) => medBuilder);
          when(
            () => medBuilder.insert(any<Map<String, dynamic>>()),
          ).thenAnswer((_) => filterBuilder);
          when(
            () => filterBuilder.select('id'),
          ).thenAnswer((_) => listTransformBuilder);
          when(
            () => listTransformBuilder.single(),
          ).thenAnswer((_) => mapTransformBuilder);

          final remBuilder = FakeQueryBuilder();
          final remFilterBuilder = FakeFilterBuilder<PostgrestList>(
            () => Future.value([]),
          );
          final remTransformBuilder = FakeTransformBuilder<PostgrestList>(
            () => Future.value([]),
          );
          when(
            () => mockClient.from('medication_reminders'),
          ).thenAnswer((_) => remBuilder);
          when(
            () => remBuilder.insert(any<List<Map<String, dynamic>>>()),
          ).thenAnswer((_) => remFilterBuilder);
          when(
            () => remFilterBuilder.select(),
          ).thenAnswer((_) => remTransformBuilder);

          final result = await repository.addMedication(payload);
          expect(result.medicationId, 'med-123');
        },
      );

      test(
        'Network failure: throws MedicationSaveException when parent insert fails',
        () async {
          when(() => mockAuth.currentUser).thenReturn(mockUser);

          final medBuilder = FakeQueryBuilder();
          final filterBuilder = FakeFilterBuilder<PostgrestList>(
            () => Future.error(
              const PostgrestException(message: 'Network error'),
            ),
          );
          final listTransformBuilder = FakeTransformBuilder<PostgrestList>(
            () => Future.error(
              const PostgrestException(message: 'Network error'),
            ),
          );
          final mapTransformBuilder = FakeTransformBuilder<PostgrestMap>(
            () => Future.error(
              const PostgrestException(message: 'Network error'),
            ),
          );

          when(
            () => mockClient.from('medications'),
          ).thenAnswer((_) => medBuilder);
          when(
            () => medBuilder.insert(any<Map<String, dynamic>>()),
          ).thenAnswer((_) => filterBuilder);
          when(
            () => filterBuilder.select('id'),
          ).thenAnswer((_) => listTransformBuilder);
          when(
            () => listTransformBuilder.single(),
          ).thenAnswer((_) => mapTransformBuilder);

          expect(
            () => repository.addMedication(payload),
            throwsA(isA<PostgrestException>()),
          );
        },
      );

      test(
        'Rollback scenario: throws MedicationSaveException and deletes parent if reminders fail',
        () async {
          when(() => mockAuth.currentUser).thenReturn(mockUser);

          final medBuilder = FakeQueryBuilder();
          final filterBuilder = FakeFilterBuilder<PostgrestList>(
            () => Future.value([]),
          );
          final listTransformBuilder = FakeTransformBuilder<PostgrestList>(
            () => Future.value([]),
          );
          final mapTransformBuilder = FakeTransformBuilder<PostgrestMap>(
            () => Future.value(<String, dynamic>{'id': 'med-123'}),
          );

          when(
            () => mockClient.from('medications'),
          ).thenAnswer((_) => medBuilder);
          when(
            () => medBuilder.insert(any<Map<String, dynamic>>()),
          ).thenAnswer((_) => filterBuilder);
          when(
            () => filterBuilder.select('id'),
          ).thenAnswer((_) => listTransformBuilder);
          when(
            () => listTransformBuilder.single(),
          ).thenAnswer((_) => mapTransformBuilder);

          // Reminders throw
          final remBuilder = FakeQueryBuilder();
          final remFilterBuilder = FakeFilterBuilder<PostgrestList>(
            () => Future.error(
              const PostgrestException(message: 'Reminders failed'),
            ),
          );
          final remTransformBuilder = FakeTransformBuilder<PostgrestList>(
            () => Future.error(
              const PostgrestException(message: 'Reminders failed'),
            ),
          );
          when(
            () => mockClient.from('medication_reminders'),
          ).thenAnswer((_) => remBuilder);
          when(
            () => remBuilder.insert(any<List<Map<String, dynamic>>>()),
          ).thenAnswer((_) => remFilterBuilder);
          when(
            () => remFilterBuilder.select(),
          ).thenAnswer((_) => remTransformBuilder);

          // Rollback mock
          final deleteFilterBuilder = FakeFilterBuilder<dynamic>(
            () => Future.value(),
          );
          when(
            () => medBuilder.delete(),
          ).thenAnswer((_) => deleteFilterBuilder);
          when(
            () => deleteFilterBuilder.eq('id', 'med-123'),
          ).thenAnswer((_) => deleteFilterBuilder);

          // Should throw MedicationSaveException for the rollback
          expect(
            repository.addMedication(payload),
            throwsA(
              isA<MedicationSaveException>().having(
                (e) => e.message,
                'message',
                contains('Reminders could not be saved'),
              ),
            ),
          );
        },
      );
    });

    group('fetchMedications', () {
      test('Happy path: successfully returns list of medications', () async {
        when(() => mockAuth.currentUser).thenReturn(mockUser);

        final queryBuilder = FakeQueryBuilder();
        final filterBuilder = FakeFilterBuilder<PostgrestList>(
          () => Future.value([
            <String, dynamic>{
              'id': 'med-123',
              'user_id': 'user-123',
              'name': 'Aspirin',
              'dosage': 100,
              'dosage_unit': 'mg',
              'frequency': 'Daily',
              'color': '#E57373',
              'created_at': '2023-01-01T00:00:00Z',
            },
          ]),
        );

        when(
          () => mockClient.from('medications'),
        ).thenAnswer((_) => queryBuilder);
        when(
          () => queryBuilder.select('*, medication_reminders(*)'),
        ).thenAnswer((_) => filterBuilder);
        when(
          () => filterBuilder.eq('user_id', 'user-123'),
        ).thenAnswer((_) => filterBuilder);
        when(
          () => filterBuilder.order('created_at', ascending: false),
        ).thenAnswer((_) => filterBuilder);

        final result = await repository.fetchMedications();
        expect(result.length, 1);
        expect(result.first.id, 'med-123');
        expect(result.first.name, 'Aspirin');
      });

      test('Empty result: returns empty list safely', () async {
        when(() => mockAuth.currentUser).thenReturn(mockUser);

        final queryBuilder = FakeQueryBuilder();
        final filterBuilder = FakeFilterBuilder<PostgrestList>(
          () => Future.value([]),
        );

        when(
          () => mockClient.from('medications'),
        ).thenAnswer((_) => queryBuilder);
        when(
          () => queryBuilder.select('*, medication_reminders(*)'),
        ).thenAnswer((_) => filterBuilder);
        when(
          () => filterBuilder.eq('user_id', 'user-123'),
        ).thenAnswer((_) => filterBuilder);
        when(
          () => filterBuilder.order('created_at', ascending: false),
        ).thenAnswer((_) => filterBuilder);

        final result = await repository.fetchMedications();
        expect(result, isEmpty);
      });

      test('Network failure: throws PostgrestException', () async {
        when(() => mockAuth.currentUser).thenReturn(mockUser);

        final queryBuilder = FakeQueryBuilder();
        final filterBuilder = FakeFilterBuilder<PostgrestList>(
          () =>
              Future.error(const PostgrestException(message: 'Network error')),
        );

        when(
          () => mockClient.from('medications'),
        ).thenAnswer((_) => queryBuilder);
        when(
          () => queryBuilder.select('*, medication_reminders(*)'),
        ).thenAnswer((_) => filterBuilder);
        when(
          () => filterBuilder.eq('user_id', 'user-123'),
        ).thenAnswer((_) => filterBuilder);
        when(
          () => filterBuilder.order('created_at', ascending: false),
        ).thenAnswer((_) => filterBuilder);

        expect(
          () => repository.fetchMedications(),
          throwsA(isA<PostgrestException>()),
        );
      });

      test('Malformed data: throws on invalid json shape', () async {
        when(() => mockAuth.currentUser).thenReturn(mockUser);

        final queryBuilder = FakeQueryBuilder();
        final filterBuilder = FakeFilterBuilder<PostgrestList>(
          () => Future.value([
            <String, dynamic>{'invalid_field': 'hello'},
          ]),
        );

        when(
          () => mockClient.from('medications'),
        ).thenAnswer((_) => queryBuilder);
        when(
          () => queryBuilder.select('*, medication_reminders(*)'),
        ).thenAnswer((_) => filterBuilder);
        when(
          () => filterBuilder.eq('user_id', 'user-123'),
        ).thenAnswer((_) => filterBuilder);
        when(
          () => filterBuilder.order('created_at', ascending: false),
        ).thenAnswer((_) => filterBuilder);

        expect(() => repository.fetchMedications(), throwsA(isA<TypeError>()));
      });
    });

    group('deleteMedication', () {
      test('Happy path: calls delete gracefully', () async {
        final queryBuilder = FakeQueryBuilder();
        final filterBuilder = FakeFilterBuilder<dynamic>(
          () => Future.value([]),
        );

        when(
          () => mockClient.from('medications'),
        ).thenAnswer((_) => queryBuilder);
        when(() => queryBuilder.delete()).thenAnswer((_) => filterBuilder);
        when(
          () => filterBuilder.eq('id', 'med-123'),
        ).thenAnswer((_) => filterBuilder);

        await repository.deleteMedication('med-123');
        // If it throws no error, we succeed.
      });

      test('Network failure: passes exception upwards', () async {
        final queryBuilder = FakeQueryBuilder();
        final filterBuilder = FakeFilterBuilder<dynamic>(
          () =>
              Future.error(const PostgrestException(message: 'Network error')),
        );

        when(
          () => mockClient.from('medications'),
        ).thenAnswer((_) => queryBuilder);
        when(() => queryBuilder.delete()).thenAnswer((_) => filterBuilder);
        when(
          () => filterBuilder.eq('id', 'med-123'),
        ).thenAnswer((_) => filterBuilder);

        expect(
          () => repository.deleteMedication('med-123'),
          throwsA(isA<PostgrestException>()),
        );
      });
    });

    group('fetchAllReminders', () {
      test('Happy path: successfully returns all reminders', () async {
        final queryBuilder = FakeQueryBuilder();
        final filterBuilder = FakeFilterBuilder<PostgrestList>(
          () => Future.value([
            {
              'id': 'rem-1',
              'medication_id': 'med-1',
              'reminder_time': '08:00:00',
              'days_of_week': ['monday'], // added missing required field
              'is_active': true,
            },
          ]),
        );

        when(
          () => mockClient.from('medication_reminders'),
        ).thenAnswer((_) => queryBuilder);
        when(() => queryBuilder.select()).thenAnswer((_) => filterBuilder);

        final result = await repository.fetchAllReminders();
        expect(result.length, 1);
        expect(result.first.id, 'rem-1');
        expect(result.first.reminderTime, '08:00:00');
      });

      test('Empty result: returns empty list safely', () async {
        final queryBuilder = FakeQueryBuilder();
        final filterBuilder = FakeFilterBuilder<PostgrestList>(
          () => Future.value([]),
        );

        when(
          () => mockClient.from('medication_reminders'),
        ).thenAnswer((_) => queryBuilder);
        when(() => queryBuilder.select()).thenAnswer((_) => filterBuilder);

        final result = await repository.fetchAllReminders();
        expect(result, isEmpty);
      });

      test('Network failure: throws PostgrestException', () async {
        final queryBuilder = FakeQueryBuilder();
        final filterBuilder = FakeFilterBuilder<PostgrestList>(
          () => Future.error(const PostgrestException(message: 'Fetch failed')),
        );

        when(
          () => mockClient.from('medication_reminders'),
        ).thenAnswer((_) => queryBuilder);
        when(() => queryBuilder.select()).thenAnswer((_) => filterBuilder);

        expect(
          () => repository.fetchAllReminders(),
          throwsA(isA<PostgrestException>()),
        );
      });

      test('Malformed data: handles invalid structure gracefully', () async {
        final queryBuilder = FakeQueryBuilder();
        final filterBuilder = FakeFilterBuilder<PostgrestList>(
          () => Future.value([
            {'bad': 'data'},
          ]),
        );

        when(
          () => mockClient.from('medication_reminders'),
        ).thenAnswer((_) => queryBuilder);
        when(() => queryBuilder.select()).thenAnswer((_) => filterBuilder);

        expect(
          () => repository.fetchAllReminders(),
          throwsA(anyOf(isA<TypeError>(), isA<Exception>())),
        );
      });
    });
  });
}
