import 'package:clinic_go/features/medication/data/medication_repository.dart';
import 'package:clinic_go/features/medication/models/medication.dart';
import 'package:clinic_go/features/medication/models/medication_reminder.dart';
import 'package:clinic_go/features/medication/presentation/views/add_medication_screen.dart';
import 'package:clinic_go/features/medication/services/missed_dose_notification_controller.dart';
import 'package:clinic_go/features/medication/services/dose_scheduling_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

class MockMissedDoseNotificationController extends Mock
    implements MissedDoseNotificationController {}

class MockDoseSchedulingService extends Mock implements DoseSchedulingService {}

class FakeMedication extends Fake implements Medication {}

class FakeMedicationReminder extends Fake implements MedicationReminder {}

// ── Mock repository ─────────────────────────────────────────────────────

class _MockMedicationRepository implements MedicationRepository {
  bool shouldFail;
  _MockMedicationRepository({this.shouldFail = false});

  @override
  Future<SavedMedicationResult> addMedication(
    AddMedicationPayload payload,
  ) async {
    if (shouldFail) {
      throw const MedicationSaveException('Rollback occurred.');
    }
    return const SavedMedicationResult(medicationId: 'mock-id', reminders: []);
  }

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

// ── Helpers ──────────────────────────────────────────────────────────────

Widget _buildScreen(MedicationRepository repo) {
  if (!GetIt.I.isRegistered<MedicationRepository>()) {
    GetIt.I.registerSingleton<MedicationRepository>(repo);
  }

  final mockController = MockMissedDoseNotificationController();
  final mockService = MockDoseSchedulingService();

  when(() => mockService.calculateUpcomingDoses(any(), any())).thenReturn([]);

  if (!GetIt.I.isRegistered<MissedDoseNotificationController>()) {
    GetIt.I.registerSingleton<MissedDoseNotificationController>(mockController);
  }
  if (!GetIt.I.isRegistered<DoseSchedulingService>()) {
    GetIt.I.registerSingleton<DoseSchedulingService>(mockService);
  }

  return MaterialApp(
    theme: ThemeData(splashFactory: NoSplash.splashFactory),
    home: AddMedicationScreen(),
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────

void main() {
  setUpAll(() {
    registerFallbackValue(FakeMedication());
    registerFallbackValue(FakeMedicationReminder());
  });

  setUp(() async => await GetIt.instance.reset());
  tearDown(() async => await GetIt.I.reset());

  testWidgets('renders all required form fields and colour swatch', (
    tester,
  ) async {
    await tester.pumpWidget(_buildScreen(_MockMedicationRepository()));
    await tester.pumpAndSettle();

    expect(find.text('Adicionar medicação'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'ex: Metformina'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'ex: 500'), findsOneWidget);
    expect(find.byKey(const Key('med_color_swatch')), findsOneWidget);
    expect(find.text('Toca para mudar'), findsOneWidget);
    expect(find.text('Cancelar'), findsOneWidget);
    expect(find.text('Guardar'), findsOneWidget);
  });

  testWidgets('tapping Save with empty fields shows validation errors', (
    tester,
  ) async {
    await tester.pumpWidget(_buildScreen(_MockMedicationRepository()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('med_save_button')));
    await tester.pump();

    expect(find.text('O nome é obrigatório'), findsOneWidget);
    expect(find.text('Introduz uma dosagem válida'), findsOneWidget);
  });

  testWidgets('Save button shows spinner while loading', (tester) async {
    final slowRepo = _SlowRepo();

    await tester.pumpWidget(_buildScreen(slowRepo));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'ex: Metformina'),
      'Aspirin',
    );
    await tester.enterText(find.widgetWithText(TextField, 'ex: 500'), '100');
    await tester.tap(find.byKey(const Key('med_save_button')));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();
  });

  testWidgets('tapping colour swatch opens colour picker bottom sheet', (
    tester,
  ) async {
    await tester.pumpWidget(_buildScreen(_MockMedicationRepository()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('med_color_swatch')));
    await tester.pumpAndSettle();

    expect(find.text('Escolhe uma cor'), findsOneWidget);
  });

  testWidgets('error message is shown when repository throws', (tester) async {
    await tester.pumpWidget(
      _buildScreen(_MockMedicationRepository(shouldFail: true)),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'ex: Metformina'),
      'Med',
    );
    await tester.enterText(find.widgetWithText(TextField, 'ex: 500'), '5');
    await tester.tap(find.byKey(const Key('med_save_button')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Rollback occurred'), findsOneWidget);
  });
}

// ── Slow repo ─────────────────────────────────────────────────────────────

class _SlowRepo implements MedicationRepository {
  @override
  Future<SavedMedicationResult> addMedication(AddMedicationPayload p) async {
    await Future.delayed(const Duration(milliseconds: 50));
    return const SavedMedicationResult(medicationId: 'id', reminders: []);
  }

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
