import 'package:clinic_go/features/auth/domain/auth_service.dart';
import 'package:clinic_go/features/calendar/data/calendar_repository.dart';
import 'package:clinic_go/features/medication/data/dose_log_repository.dart';
import 'package:clinic_go/features/medication/data/medication_repository.dart';
import 'package:clinic_go/features/medication/services/dose_scheduling_service.dart';
import 'package:clinic_go/features/medication/services/local_notification_gateway.dart';
import 'package:clinic_go/features/medication/services/missed_dose_notification_controller.dart';
import 'package:clinic_go/features/medication/services/pending_notification_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:clinic_go/main.dart' as app;

import '../test/helpers/medication_mocks.dart';

class MockMedicationRepository extends Mock implements MedicationRepository {}

class MockAuthService extends Mock implements AuthService {}

class MockSupabaseClient extends Mock implements SupabaseClient {}

// ── Setup ─────────────────────────────────────────────────────────────────────

Future<void> _bootApp(
  WidgetTester tester, {
  required MockMedicationRepository mockMedRepo,
}) async {
  SharedPreferences.setMockInitialValues({});

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockStreamHandler(
        const EventChannel('com.llfbandit.app_links/events'),
        _MockStreamHandler(),
      );
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockStreamHandler(
        const EventChannel('com.llfbandit.app_links/messages'),
        _MockStreamHandler(),
      );

  try {
    await Supabase.initialize(
      url: 'https://test.supabase.co',
      anonKey: 'test-anon-key',
    );
  } catch (_) {}

  final getIt = GetIt.instance;
  await getIt.reset();
  getIt.allowReassignment = true;

  final mockAuth = MockAuthService();
  when(
    () => mockAuth.authStateChanges,
  ).thenAnswer((_) => Stream.fromIterable([true]));
  when(() => mockAuth.isLoggedIn).thenReturn(true);
  when(() => mockAuth.currentUserEmail).thenReturn('user@example.com');
  when(() => mockAuth.currentUserMetadata).thenReturn(const {});

  getIt.registerSingleton<AuthService>(mockAuth);
  getIt.registerSingleton<SupabaseClient>(MockSupabaseClient());
  getIt.registerSingleton<MedicationRepository>(mockMedRepo);
  getIt.registerSingleton<DoseLogRepository>(InMemoryDoseLogRepository());
  getIt.registerLazySingleton<PendingNotificationStore>(
    () => const PendingNotificationStore(),
  );
  getIt.registerLazySingleton<DoseSchedulingService>(
    () => const DoseSchedulingService(),
  );
  getIt.registerSingleton<LocalNotificationGateway>(
    const NoopLocalNotificationGateway(),
  );
  getIt.registerSingleton<MissedDoseNotificationController>(
    MissedDoseNotificationController(
      notificationGateway: getIt<LocalNotificationGateway>(),
      doseLogRepository: getIt<DoseLogRepository>(),
      pendingNotificationStore: getIt<PendingNotificationStore>(),
    ),
  );
  getIt.registerSingleton<CalendarRepository>(EmptyCalendarRepository());

  final navigatorKey = GlobalKey<NavigatorState>();
  await tester.pumpWidget(app.ClinicGO(navigatorKey: navigatorKey));
  await tester.pumpAndSettle(const Duration(seconds: 1));
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(
      const AddMedicationPayload(
        name: '',
        dosageAmount: 0,
        dosageUnit: 'mg',
        frequency: '',
        color: Colors.white,
        reminderTimes: [],
        daysOfWeek: [],
      ),
    );
  });

  group('Add Medication Journey (US02)', () {
    late MockMedicationRepository mockMedRepo;

    setUp(() {
      mockMedRepo = MockMedicationRepository();
      when(() => mockMedRepo.fetchMedications()).thenAnswer((_) async => []);
      when(() => mockMedRepo.fetchAllReminders()).thenAnswer((_) async => []);
      when(() => mockMedRepo.addMedication(any())).thenAnswer(
        (_) async =>
            const SavedMedicationResult(medicationId: 'new-med', reminders: []),
      );
    });

    testWidgets(
      'US02: filling name + dosage and saving shows success snackbar',
      (tester) async {
        await _bootApp(tester, mockMedRepo: mockMedRepo);

        // Navigate to MEDS tab
        await tester.tap(find.text('MEDS'));
        await tester.pumpAndSettle();

        // Empty state — tap add button
        expect(find.text('Nenhum medicamento'), findsOneWidget);
        await tester.tap(find.text('Adicionar medicamento'));
        await tester.pumpAndSettle();

        // On AddMedicationScreen
        expect(find.text('Adicionar medicação'), findsOneWidget);

        // Fill name
        await tester.enterText(
          find.byKey(const Key('med_name_field')),
          'Paracetamol',
        );
        await tester.pump();

        // Fill dosage
        await tester.enterText(
          find.byKey(const Key('med_dosage_field')),
          '500',
        );
        await tester.pump();

        // Save
        await tester.tap(find.byKey(const Key('med_save_button')));
        await tester.pumpAndSettle();

        // Success snackbar
        expect(find.text('Medication saved successfully!'), findsOneWidget);
      },
    );

    testWidgets(
      'US02: submitting with blank name shows Name is required error',
      (tester) async {
        await _bootApp(tester, mockMedRepo: mockMedRepo);

        await tester.tap(find.text('MEDS'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Adicionar medicamento'));
        await tester.pumpAndSettle();

        // Tap save without entering name or dosage
        await tester.tap(find.byKey(const Key('med_save_button')));
        await tester.pump();

        expect(find.text('Name is required'), findsOneWidget);
        expect(find.text('Medication saved successfully!'), findsNothing);
      },
    );

    testWidgets(
      'US02: add form shows Adicionar medicação title and colour swatch',
      (tester) async {
        await _bootApp(tester, mockMedRepo: mockMedRepo);

        await tester.tap(find.text('MEDS'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Adicionar medicamento'));
        await tester.pumpAndSettle();

        expect(find.text('Adicionar medicação'), findsOneWidget);
        expect(find.byKey(const Key('med_color_swatch')), findsOneWidget);
        expect(find.byKey(const Key('med_save_button')), findsOneWidget);
      },
    );
  });
}

class _MockStreamHandler extends MockStreamHandler {
  @override
  void onListen(Object? arguments, MockStreamHandlerEventSink events) {}

  @override
  void onCancel(Object? arguments) {}
}
