import 'package:clinic_go/features/medication/data/medication_repository.dart';
import 'package:clinic_go/features/medication/models/medication.dart';
import 'package:clinic_go/features/medication/models/medication_reminder.dart';
import 'package:clinic_go/features/medication/presentation/views/edit_medication_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

// ── Fixture ───────────────────────────────────────────────────────────────────

Medication _med() => Medication(
  id: 'med-1',
  userId: 'u1',
  name: 'Metformina',
  dosageAmount: 500,
  dosageUnit: 'mg',
  frequency: 'Once daily',
  color: const Color(0xFF4E84E5),
  createdAt: DateTime(2026, 1, 1),
  notes: 'com o pequeno-almoço',
);

// ── Repositories ──────────────────────────────────────────────────────────────

class _SuccessRepo implements MedicationRepository {
  @override
  Future<SavedMedicationResult> addMedication(AddMedicationPayload p) async =>
      const SavedMedicationResult(medicationId: 'id', reminders: []);

  @override
  Future<void> editMedication(EditMedicationPayload payload) async {}

  @override
  Future<List<Medication>> fetchMedications() async => [];

  @override
  Future<void> deleteMedication(String id) async {}

  @override
  Future<List<MedicationReminder>> fetchAllReminders() async => [];

  @override
  Future<List<MedicationReminder>> fetchRemindersForMedication(
    String medicationId,
  ) async => [];
}

class _FailEditRepo extends _SuccessRepo {
  @override
  Future<void> editMedication(EditMedicationPayload payload) async =>
      throw Exception('Server error');
}

// ── Helper ────────────────────────────────────────────────────────────────────

Widget _buildApp(MedicationRepository repo, {Medication? medication}) {
  GetIt.I.registerSingleton<MedicationRepository>(repo);
  final med = medication ?? _med();
  return MaterialApp(
    home: Builder(
      builder: (ctx) => Scaffold(
        body: ElevatedButton(
          onPressed: () => Navigator.of(ctx).push(
            MaterialPageRoute<bool>(
              builder: (_) => EditMedicationScreen(medication: med),
            ),
          ),
          child: const Text('Open'),
        ),
      ),
    ),
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  setUp(() async => GetIt.I.reset());
  tearDown(() async => GetIt.I.reset());

  group('EditMedicationScreen – rendering', () {
    testWidgets('shows title and pre-filled name and dosage', (tester) async {
      await tester.pumpWidget(_buildApp(_SuccessRepo()));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Editar medicação'), findsOneWidget);
      expect(find.text('Metformina'), findsOneWidget);
      expect(find.text('500'), findsOneWidget);
    });

    testWidgets('shows Guardar alterações and Cancelar buttons', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp(_SuccessRepo()));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Guardar alterações'), findsOneWidget);
      expect(find.text('Cancelar'), findsOneWidget);
    });

    testWidgets('shows colour swatch', (tester) async {
      await tester.pumpWidget(_buildApp(_SuccessRepo()));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('edit_med_color_swatch')), findsOneWidget);
    });
  });

  group('EditMedicationScreen – validation', () {
    testWidgets('Save with blank name shows name error', (tester) async {
      final med = Medication(
        id: 'med-1',
        userId: 'u1',
        name: '',
        dosageAmount: 500,
        dosageUnit: 'mg',
        frequency: 'Once daily',
        color: Colors.blue,
        createdAt: DateTime(2026, 1, 1),
      );

      await tester.pumpWidget(_buildApp(_SuccessRepo(), medication: med));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('edit_med_save_button')));
      await tester.pump();

      expect(find.text('Name is required'), findsOneWidget);
    });
  });

  group('EditMedicationScreen – success', () {
    testWidgets('successful save shows snackbar and pops screen', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp(_SuccessRepo()));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('edit_med_save_button')));
      await tester.pumpAndSettle();

      expect(find.text('Medicamento atualizado com sucesso!'), findsOneWidget);
      // Screen popped — home button is visible again
      expect(find.text('Open'), findsOneWidget);
    });
  });

  group('EditMedicationScreen – error', () {
    testWidgets('repo error shows error message in form', (tester) async {
      await tester.pumpWidget(_buildApp(_FailEditRepo()));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('edit_med_save_button')));
      await tester.pumpAndSettle();

      expect(
        find.text('Could not save changes. Please try again.'),
        findsOneWidget,
      );
    });
  });
}
