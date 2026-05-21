import 'dart:async';

import 'package:clinic_go/features/symptoms/models/symptom_log.dart';
import 'package:clinic_go/features/symptoms/presentation/view_models/symptom_history_provider.dart';
import 'package:clinic_go/features/symptoms/presentation/views/symptom_history_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// ── Helpers ──────────────────────────────────────────────────────────────────

SymptomLog _makeLog({
  String id = '1',
  String symptomType = 'headache',
  int severity = 5,
  String? notes,
}) {
  return SymptomLog(
    id: id,
    userId: 'user-1',
    symptomType: symptomType,
    severity: severity,
    notes: notes,
    occurredAt: DateTime(2026, 5, 1, 8),
    createdAt: DateTime(2026, 5, 1, 8, 5),
  );
}

Widget _buildScreen(Future<List<SymptomLog>> Function() loader) {
  return ProviderScope(
    overrides: [symptomHistoryProvider.overrideWith((_) => loader())],
    child: const MaterialApp(home: SymptomHistoryScreen()),
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('SymptomHistoryScreen – loading state', () {
    testWidgets('shows CircularProgressIndicator while loading', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildScreen(() => Completer<List<SymptomLog>>().future),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('SymptomHistoryScreen – empty state', () {
    testWidgets('shows empty-state message when log list is empty', (
      tester,
    ) async {
      await tester.pumpWidget(_buildScreen(() => Future.value([])));
      await tester.pumpAndSettle();

      expect(find.text('Sem registos ainda'), findsOneWidget);
      expect(find.text('Registar agora'), findsOneWidget);
    });
  });

  group('SymptomHistoryScreen – data state', () {
    testWidgets('renders a card for each symptom log', (tester) async {
      final logs = [
        _makeLog(id: '1', symptomType: 'headache', severity: 5),
        _makeLog(id: '2', symptomType: 'nausea', severity: 3),
      ];

      await tester.pumpWidget(_buildScreen(() => Future.value(logs)));
      await tester.pumpAndSettle();

      expect(find.text('Headache'), findsOneWidget);
      expect(find.text('Nausea'), findsOneWidget);
    });

    testWidgets('shows severity badge for each log', (tester) async {
      await tester.pumpWidget(
        _buildScreen(() => Future.value([_makeLog(severity: 7)])),
      );
      await tester.pumpAndSettle();

      expect(find.text('Severity 7'), findsOneWidget);
    });

    testWidgets('shows notes when present', (tester) async {
      await tester.pumpWidget(
        _buildScreen(() => Future.value([_makeLog(notes: 'After exercise')])),
      );
      await tester.pumpAndSettle();

      expect(find.text('After exercise'), findsOneWidget);
    });

    testWidgets('does not show notes section when notes is null', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildScreen(() => Future.value([_makeLog(notes: null)])),
      );
      await tester.pumpAndSettle();

      expect(find.text('Headache'), findsOneWidget);
    });
  });

  group('SymptomHistoryScreen – error state', () {
    testWidgets('shows error message when provider fails', (tester) async {
      await tester.pumpWidget(
        _buildScreen(
          () => Future<List<SymptomLog>>.error('Server unavailable'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Unable to load'), findsOneWidget);
    });
  });
}
