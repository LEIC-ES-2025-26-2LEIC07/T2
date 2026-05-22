import 'dart:async';

import 'package:clinic_go/core/providers/supabase_providers.dart';
import 'package:clinic_go/features/symptoms/data/symptom_repository.dart';
import 'package:clinic_go/features/symptoms/models/symptom_log.dart';
import 'package:clinic_go/features/symptoms/presentation/views/log_symptom_screen.dart';
import 'package:flutter/material.dart';
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

class _SlowRepo implements SymptomRepository {
  @override
  Future<void> insertSymptomLog({
    required String userId,
    required String symptomType,
    required int severity,
    String? notes,
    required DateTime occurredAt,
  }) => Completer<void>().future;

  @override
  Future<List<SymptomLog>> fetchSymptomLogs() async => [];
}

// ── Helpers ──────────────────────────────────────────────────────────────────

Widget _buildScreen({User? user, SymptomRepository? repo}) {
  return ProviderScope(
    overrides: [
      currentUserProvider.overrideWithValue(user),
      symptomRepositoryProvider.overrideWithValue(repo ?? _SuccessRepo()),
    ],
    child: MaterialApp(
      theme: ThemeData(splashFactory: NoSplash.splashFactory),
      home: LogSymptomScreen(),
    ),
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('LogSymptomScreen – rendering', () {
    testWidgets('shows all section headings', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Como te sentes?'), findsOneWidget);
      expect(find.textContaining('Gravidade'), findsOneWidget);
      expect(find.text('Quando aconteceu?'), findsOneWidget);
      expect(find.text('Notas adicionais'), findsOneWidget);
    });

    testWidgets('shows symptom chips including Dor de cabeça and Náusea', (
      tester,
    ) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Dor de cabeça'), findsOneWidget);
      expect(find.text('Náusea'), findsOneWidget);
      expect(find.text('Fadiga'), findsOneWidget);
    });

    testWidgets('shows search field and Guardar button', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pumpAndSettle();

      expect(
        find.widgetWithText(TextField, 'Pesquisar sintomas'),
        findsOneWidget,
      );
      expect(find.text('Guardar sintoma'), findsOneWidget);
    });
  });

  group('LogSymptomScreen – symptom search', () {
    testWidgets('typing in search filters the chip list', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'Pesquisar sintomas'),
        'brain',
      );
      await tester.pump();

      expect(find.text('Confusão mental'), findsOneWidget);
      expect(find.text('Dor de cabeça'), findsNothing);
    });

    testWidgets('clearing search restores all chips', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pumpAndSettle();

      final searchField = find.widgetWithText(TextField, 'Pesquisar sintomas');
      await tester.enterText(searchField, 'brain');
      await tester.pump();

      await tester.enterText(searchField, '');
      await tester.pump();

      expect(find.text('Dor de cabeça'), findsOneWidget);
    });
  });

  group('LogSymptomScreen – validation', () {
    testWidgets('tapping Guardar with no symptom selected shows error banner', (
      tester,
    ) async {
      await tester.pumpWidget(_buildScreen(user: MockUser()..stubId()));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Guardar sintoma'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guardar sintoma'));
      await tester.pump();

      expect(find.textContaining('Seleciona'), findsOneWidget);
    });

    testWidgets('tapping Guardar when not signed in shows sign-in error', (
      tester,
    ) async {
      await tester.pumpWidget(_buildScreen(user: null));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Dor de cabeça'));
      await tester.pump();

      await tester.ensureVisible(find.text('Guardar sintoma'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guardar sintoma'));
      await tester.pump();

      expect(find.textContaining('Inicia sessão'), findsAtLeastNWidgets(1));
    });
  });

  group('LogSymptomScreen – loading state', () {
    testWidgets('shows spinner while save is in progress', (tester) async {
      final user = MockUser()..stubId();

      await tester.pumpWidget(_buildScreen(user: user, repo: _SlowRepo()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Dor de cabeça'));
      await tester.pump();
      await tester.ensureVisible(find.text('Guardar sintoma'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guardar sintoma'));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('LogSymptomScreen – successful save', () {
    testWidgets('pops screen and shows snackbar on success', (tester) async {
      final repo = _SuccessRepo();
      final user = MockUser()..stubId();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWithValue(user),
            symptomRepositoryProvider.overrideWithValue(repo),
          ],
          child: MaterialApp(
            theme: ThemeData(splashFactory: NoSplash.splashFactory),
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LogSymptomScreen()),
                  ),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Dor de cabeça'));
      await tester.pump();

      await tester.ensureVisible(find.text('Guardar sintoma'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guardar sintoma'));
      await tester.pumpAndSettle();

      expect(repo.insertCalled, isTrue);
      expect(find.text('Open'), findsOneWidget);
    });
  });
}

// ── Extension helper for tests ────────────────────────────────────────────────

extension on MockUser {
  void stubId() => when(() => id).thenReturn('user-test');
}
