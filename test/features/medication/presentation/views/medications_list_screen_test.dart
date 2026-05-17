import 'package:clinic_go/features/medication/data/medication_repository.dart';
import 'package:clinic_go/features/medication/models/medication.dart';
import 'package:clinic_go/features/medication/models/medication_reminder.dart';
import 'package:clinic_go/features/medication/presentation/views/medications_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

// ── Mock repositories ───────────────────────────────────────────────

class _EmptyRepo implements MedicationRepository {
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

class _LoadedRepo implements MedicationRepository {
  @override
  Future<SavedMedicationResult> addMedication(AddMedicationPayload p) async =>
      const SavedMedicationResult(medicationId: 'id', reminders: []);

  @override
  Future<void> editMedication(EditMedicationPayload payload) async {}

  @override
  Future<List<Medication>> fetchMedications() async => [
    Medication(
      id: 'a',
      userId: 'u1',
      name: 'Lisinopril',
      dosageAmount: 10,
      dosageUnit: 'mg',
      frequency: 'Once daily',
      color: const Color(0xFF4E84E5),
      createdAt: DateTime(2026, 1, 1),
    ),
    Medication(
      id: 'b',
      userId: 'u1',
      name: 'Aspirin',
      dosageAmount: 100,
      dosageUnit: 'mg',
      frequency: 'Twice daily',
      color: const Color(0xFFE53935),
      createdAt: DateTime(2026, 1, 2),
    ),
  ];

  @override
  Future<void> deleteMedication(String id) async {}

  @override
  Future<List<MedicationReminder>> fetchAllReminders() async => [];

  @override
  Future<List<MedicationReminder>> fetchRemindersForMedication(
    String medicationId,
  ) async => [];
}

class _ErrorRepo implements MedicationRepository {
  @override
  Future<SavedMedicationResult> addMedication(AddMedicationPayload p) async =>
      const SavedMedicationResult(medicationId: 'id', reminders: []);

  @override
  Future<void> editMedication(EditMedicationPayload payload) async {}

  @override
  Future<List<Medication>> fetchMedications() async =>
      throw Exception('Network error');

  @override
  Future<void> deleteMedication(String id) async {}

  @override
  Future<List<MedicationReminder>> fetchAllReminders() async => [];

  @override
  Future<List<MedicationReminder>> fetchRemindersForMedication(
    String medicationId,
  ) async => [];
}

// ── Helper ──────────────────────────────────────────────────────────

Widget _buildScreen(MedicationRepository repo) {
  GetIt.I.registerSingleton<MedicationRepository>(repo);
  return const MaterialApp(home: Scaffold(body: MedicationsListScreen()));
}

// ── Tests ───────────────────────────────────────────────────────────

void main() {
  setUp(() async => await GetIt.I.reset());
  tearDown(() async => await GetIt.I.reset());

  testWidgets('shows empty state when no medications', (tester) async {
    await tester.pumpWidget(_buildScreen(_EmptyRepo()));
    await tester.pumpAndSettle();

    expect(find.text('Nenhum medicamento'), findsOneWidget);
    expect(find.text('Aspirin'), findsNothing);
  });

  testWidgets('renders medication cards with correct colours', (tester) async {
    await tester.pumpWidget(_buildScreen(_LoadedRepo()));
    await tester.pumpAndSettle();

    expect(find.text('Lisinopril'), findsOneWidget);
    expect(find.text('Aspirin'), findsOneWidget);

    // AnimatedContainer(color:) uses BoxDecoration internally → DecoratedBox
    final colours = tester
        .widgetList<DecoratedBox>(find.byType(DecoratedBox))
        .map((b) => (b.decoration as BoxDecoration?)?.color)
        .whereType<Color>()
        .toList();

    expect(colours, contains(const Color(0xFF4E84E5)));
    expect(colours, contains(const Color(0xFFE53935)));
  });

  testWidgets('tapping EDITAR expands a card to show details', (tester) async {
    await tester.pumpWidget(_buildScreen(_LoadedRepo()));
    await tester.pumpAndSettle();

    expect(find.text('FECHAR'), findsNothing);

    await tester.tap(find.text('EDITAR').first);
    await tester.pumpAndSettle();

    expect(find.text('FECHAR'), findsOneWidget);
  });

  testWidgets('tapping FECHAR collapses the expanded card', (tester) async {
    await tester.pumpWidget(_buildScreen(_LoadedRepo()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('EDITAR').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('FECHAR'));
    await tester.pumpAndSettle();

    expect(find.text('FECHAR'), findsNothing);
  });

  testWidgets('shows error state and Retry button on fetch failure', (
    tester,
  ) async {
    await tester.pumpWidget(_buildScreen(_ErrorRepo()));
    await tester.pumpAndSettle();

    expect(
      find.text('Could not load medications. Please try again.'),
      findsOneWidget,
    );
    expect(find.text('Retry'), findsOneWidget);
  });
}
