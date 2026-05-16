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

// ── Mock repository ─────────────────────────────────────────────────

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

// ── Helpers ─────────────────────────────────────────────────────────

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

  return const MaterialApp(home: AddMedicationScreen());
}

// ── Tests ───────────────────────────────────────────────────────────

void main() {
  setUpAll(() {
    registerFallbackValue(FakeMedication());
    registerFallbackValue(FakeMedicationReminder());
  });

  setUp(() async {
    final getIt = GetIt.instance;
    await getIt.reset();
  });
  tearDown(() async => await GetIt.I.reset());

  testWidgets('renders all required form fields and colour swatch', (
    tester,
  ) async {
    await tester.pumpWidget(_buildScreen(_MockMedicationRepository()));
    await tester.pumpAndSettle();

    expect(find.text('add med'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'name'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'dosage'), findsOneWidget);
    // colour swatch container (GestureDetector child)
    expect(find.byType(GestureDetector), findsWidgets);
    expect(find.text('tap to\nchange\nthe color'), findsOneWidget);
    expect(find.text('cancel'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
  });

  testWidgets('tapping Save with empty fields shows validation errors', (
    tester,
  ) async {
    await tester.pumpWidget(_buildScreen(_MockMedicationRepository()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('med_save_button')));
    await tester.pump();

    expect(find.text('Name is required'), findsOneWidget);
    expect(find.text('Enter a valid dosage'), findsOneWidget);
  });

  testWidgets('Save button shows spinner while loading', (tester) async {
    // Use a slow-completing repo
    final slowRepo = _SlowRepo();

    await tester.pumpWidget(_buildScreen(slowRepo));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, 'name'), 'Aspirin');
    await tester.enterText(find.widgetWithText(TextField, 'dosage'), '100');
    await tester.tap(find.byKey(const Key('med_save_button')));
    await tester.pump(); // start async

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();
  });

  testWidgets('tapping colour swatch opens colour picker bottom sheet', (
    tester,
  ) async {
    await tester.pumpWidget(_buildScreen(_MockMedicationRepository()));
    await tester.pumpAndSettle();

    // The colour swatch is the first GestureDetector that is a plain Container
    final swatch = find.byWidgetPredicate((w) => w is GestureDetector);
    await tester.tap(swatch.first);
    await tester.pumpAndSettle();

    expect(find.text('Choose a colour'), findsOneWidget);
  });

  testWidgets('error message is shown when repository throws', (tester) async {
    await tester.pumpWidget(
      _buildScreen(_MockMedicationRepository(shouldFail: true)),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, 'name'), 'Med');
    await tester.enterText(find.widgetWithText(TextField, 'dosage'), '5');
    await tester.tap(find.byKey(const Key('med_save_button')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Rollback occurred'), findsOneWidget);
  });
}

// Slow mock — delays so the test can observe the loading spinner.
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
