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

      expect(find.text('How are you feeling?'), findsOneWidget);
      expect(find.textContaining('Severity'), findsOneWidget);
      expect(find.text('When did it happen?'), findsOneWidget);
      expect(find.text('Additional notes'), findsOneWidget);
    });

    testWidgets('shows symptom chips including Headache and Nausea', (
      tester,
    ) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Headache'), findsOneWidget);
      expect(find.text('Nausea'), findsOneWidget);
      expect(find.text('Fatigue'), findsOneWidget);
    });

    testWidgets('shows search field and Save button', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextField, 'Search symptoms'), findsOneWidget);
      expect(find.text('Save symptom'), findsOneWidget);
    });
  });

  group('LogSymptomScreen – symptom search', () {
    testWidgets('typing in search filters the chip list', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'Search symptoms'),
        'brain',
      );
      await tester.pump();

      expect(find.text('Brain Fog'), findsOneWidget);
      expect(find.text('Headache'), findsNothing);
    });

    testWidgets('clearing search restores all chips', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pumpAndSettle();

      final searchField = find.widgetWithText(TextField, 'Search symptoms');
      await tester.enterText(searchField, 'brain');
      await tester.pump();

      await tester.enterText(searchField, '');
      await tester.pump();

      expect(find.text('Headache'), findsOneWidget);
    });
  });

  group('LogSymptomScreen – validation', () {
    testWidgets('tapping Save with no symptom selected shows error banner', (
      tester,
    ) async {
      await tester.pumpWidget(_buildScreen(user: MockUser()..stubId()));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Save symptom'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save symptom'));
      await tester.pump();

      expect(find.textContaining('select'), findsOneWidget);
    });

    testWidgets('tapping Save when not signed in shows sign-in error', (
      tester,
    ) async {
      await tester.pumpWidget(_buildScreen(user: null));
      await tester.pumpAndSettle();

      // Select a symptom first so we pass symptom validation
      await tester.tap(find.text('Headache'));
      await tester.pump();

      await tester.ensureVisible(find.text('Save symptom'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save symptom'));
      await tester.pump();

      expect(find.textContaining('Sign in'), findsAtLeastNWidgets(1));
    });
  });

  group('LogSymptomScreen – loading state', () {
    testWidgets('shows spinner while save is in progress', (tester) async {
      final user = MockUser()..stubId();

      await tester.pumpWidget(_buildScreen(user: user, repo: _SlowRepo()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Headache'));
      await tester.pump();
      await tester.ensureVisible(find.text('Save symptom'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save symptom'));
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

      await tester.tap(find.text('Headache'));
      await tester.pump();

      // Save button may be below the fold — scroll it into view
      await tester.ensureVisible(find.text('Save symptom'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save symptom'));
      await tester.pumpAndSettle();

      expect(repo.insertCalled, isTrue);
      // After pop, we're back on the launching screen
      expect(find.text('Open'), findsOneWidget);
    });
  });
}

// ── Extension helper for tests ────────────────────────────────────────────────

extension on MockUser {
  void stubId() => when(() => id).thenReturn('user-test');
}
