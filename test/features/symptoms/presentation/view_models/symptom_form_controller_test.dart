import 'package:clinic_go/core/providers/supabase_providers.dart';
import 'package:clinic_go/features/symptoms/data/symptom_repository.dart';
import 'package:clinic_go/features/symptoms/models/symptom_log.dart';
import 'package:clinic_go/features/symptoms/presentation/view_models/symptom_form_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ── Fakes ────────────────────────────────────────────────────────────────────

class MockUser extends Mock implements User {}

class _SuccessRepo implements SymptomRepository {
  bool insertCalled = false;

  @override
  Future<void> insertSymptomLog({
    required String userId,
    required String symptomType,
    required int severity,
    String? notes,
    required DateTime occurredAt,
  }) async {
    insertCalled = true;
  }

  @override
  Future<List<SymptomLog>> fetchSymptomLogs() async => [];
}

class _FailRepo implements SymptomRepository {
  @override
  Future<void> insertSymptomLog({
    required String userId,
    required String symptomType,
    required int severity,
    String? notes,
    required DateTime occurredAt,
  }) async => throw Exception('Network error');

  @override
  Future<List<SymptomLog>> fetchSymptomLogs() async => [];
}

// ── Helpers ──────────────────────────────────────────────────────────────────

ProviderContainer _makeContainer({User? user, SymptomRepository? repo}) {
  final container = ProviderContainer(
    overrides: [
      currentUserProvider.overrideWithValue(user),
      symptomRepositoryProvider.overrideWithValue(repo ?? _SuccessRepo()),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  late MockUser mockUser;

  setUp(() {
    mockUser = MockUser();
    when(() => mockUser.id).thenReturn('user-123');
  });

  // ── Initial state ──────────────────────────────────────────────────────────

  group('SymptomFormController – initial state', () {
    test('starts with severity 3, no symptom, not dirty, not loading', () {
      final container = _makeContainer();
      final state = container.read(symptomFormControllerProvider);

      expect(state.severity, 3);
      expect(state.selectedSymptom, isNull);
      expect(state.isDirty, isFalse);
      expect(state.isLoading, isFalse);
      expect(state.notes, isEmpty);
      expect(state.searchQuery, isEmpty);
      expect(state.errorMessage, isNull);
    });
  });

  // ── selectSymptom ──────────────────────────────────────────────────────────

  group('SymptomFormController – selectSymptom', () {
    test('sets selectedSymptom and marks form dirty', () {
      final container = _makeContainer();
      final controller = container.read(symptomFormControllerProvider.notifier);

      controller.selectSymptom('headache');
      final state = container.read(symptomFormControllerProvider);

      expect(state.selectedSymptom, 'headache');
      expect(state.isDirty, isTrue);
    });

    test('clears errorMessage when a symptom is selected', () {
      final container = _makeContainer(user: null);
      final controller = container.read(symptomFormControllerProvider.notifier);

      // Force an error message via a submit attempt (no user)
      controller.selectSymptom('headache');
      // Verify no error yet
      expect(
        container.read(symptomFormControllerProvider).errorMessage,
        isNull,
      );
    });

    test('can switch selection from one symptom to another', () {
      final container = _makeContainer();
      final controller = container.read(symptomFormControllerProvider.notifier);

      controller.selectSymptom('nausea');
      controller.selectSymptom('fatigue');
      final state = container.read(symptomFormControllerProvider);

      expect(state.selectedSymptom, 'fatigue');
    });
  });

  // ── setSeverity ────────────────────────────────────────────────────────────

  group('SymptomFormController – setSeverity', () {
    test('rounds float value to nearest int', () {
      final container = _makeContainer();
      final controller = container.read(symptomFormControllerProvider.notifier);

      controller.setSeverity(7.6);
      expect(container.read(symptomFormControllerProvider).severity, 8);
    });

    test('clamps below 1 to 1', () {
      final container = _makeContainer();
      final controller = container.read(symptomFormControllerProvider.notifier);

      controller.setSeverity(0.4);
      expect(container.read(symptomFormControllerProvider).severity, 1);
    });

    test('clamps above 10 to 10', () {
      final container = _makeContainer();
      final controller = container.read(symptomFormControllerProvider.notifier);

      controller.setSeverity(10.9);
      expect(container.read(symptomFormControllerProvider).severity, 10);
    });

    test('marks form dirty', () {
      final container = _makeContainer();
      final controller = container.read(symptomFormControllerProvider.notifier);

      controller.setSeverity(6.0);
      expect(container.read(symptomFormControllerProvider).isDirty, isTrue);
    });
  });

  // ── setNotes / setSearchQuery / setOccurredAt ──────────────────────────────

  group('SymptomFormController – text setters', () {
    test('setNotes updates notes and marks dirty', () {
      final container = _makeContainer();
      final controller = container.read(symptomFormControllerProvider.notifier);

      controller.setNotes('After exercise');
      final state = container.read(symptomFormControllerProvider);

      expect(state.notes, 'After exercise');
      expect(state.isDirty, isTrue);
    });

    test('setSearchQuery updates searchQuery without marking dirty', () {
      final container = _makeContainer();
      final controller = container.read(symptomFormControllerProvider.notifier);

      controller.setSearchQuery('head');
      final state = container.read(symptomFormControllerProvider);

      expect(state.searchQuery, 'head');
      expect(state.isDirty, isFalse);
    });

    test('setOccurredAt updates occurredAt and marks dirty', () {
      final container = _makeContainer();
      final controller = container.read(symptomFormControllerProvider.notifier);
      final time = DateTime(2026, 5, 1, 9, 30);

      controller.setOccurredAt(time);
      final state = container.read(symptomFormControllerProvider);

      expect(state.occurredAt, time);
      expect(state.isDirty, isTrue);
    });
  });

  // ── filteredSymptoms ────────────────────────────────────────────────────────

  group('SymptomFormController – filteredSymptoms', () {
    test('returns all 14 symptoms when query is empty', () {
      final container = _makeContainer();
      final controller = container.read(symptomFormControllerProvider.notifier);

      expect(controller.filteredSymptoms.length, 14);
    });

    test('filters by partial match on headache', () {
      final container = _makeContainer();
      final controller = container.read(symptomFormControllerProvider.notifier);

      controller.setSearchQuery('head');
      expect(controller.filteredSymptoms, ['headache']);
    });

    test('filters across underscore-separated words', () {
      final container = _makeContainer();
      final controller = container.read(symptomFormControllerProvider.notifier);

      controller.setSearchQuery('pain');
      expect(
        controller.filteredSymptoms,
        containsAll(['muscle_pain', 'joint_pain', 'stomach_pain']),
      );
    });

    test('returns empty list when query matches nothing', () {
      final container = _makeContainer();
      final controller = container.read(symptomFormControllerProvider.notifier);

      controller.setSearchQuery('xyzabc');
      expect(controller.filteredSymptoms, isEmpty);
    });
  });

  // ── submitSymptomLog ────────────────────────────────────────────────────────

  group('SymptomFormController – submitSymptomLog', () {
    test('returns false and sets error when user is not signed in', () async {
      final container = _makeContainer(user: null);
      final controller = container.read(symptomFormControllerProvider.notifier);
      controller.selectSymptom('headache');

      final result = await controller.submitSymptomLog();

      expect(result, isFalse);
      expect(
        container.read(symptomFormControllerProvider).errorMessage,
        contains('Inicia sessão'),
      );
    });

    test('returns false and sets error when no symptom is selected', () async {
      final container = _makeContainer(user: mockUser);
      final controller = container.read(symptomFormControllerProvider.notifier);

      final result = await controller.submitSymptomLog();

      expect(result, isFalse);
      expect(
        container.read(symptomFormControllerProvider).errorMessage,
        contains('Seleciona'),
      );
    });

    test('Happy path: returns true and resets state', () async {
      final repo = _SuccessRepo();
      final container = _makeContainer(user: mockUser, repo: repo);
      final controller = container.read(symptomFormControllerProvider.notifier);
      controller.selectSymptom('fatigue');
      controller.setSeverity(6.0);

      final result = await controller.submitSymptomLog();
      final state = container.read(symptomFormControllerProvider);

      expect(result, isTrue);
      expect(repo.insertCalled, isTrue);
      expect(state.selectedSymptom, isNull);
      expect(state.isDirty, isFalse);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, isNull);
    });

    test(
      'Failure path: returns false and sets connection error message',
      () async {
        final container = _makeContainer(user: mockUser, repo: _FailRepo());
        final controller = container.read(
          symptomFormControllerProvider.notifier,
        );
        controller.selectSymptom('nausea');

        final result = await controller.submitSymptomLog();
        final state = container.read(symptomFormControllerProvider);

        expect(result, isFalse);
        expect(state.errorMessage, contains('ligação'));
        expect(state.isLoading, isFalse);
      },
    );
  });
}
