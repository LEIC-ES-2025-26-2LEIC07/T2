import 'package:clinic_go/features/auth/domain/auth_service.dart';
import 'package:clinic_go/features/calendar/data/calendar_repository.dart';
import 'package:clinic_go/features/medication/data/dose_log_repository.dart';
import 'package:clinic_go/features/medication/data/medication_repository.dart';
import 'package:clinic_go/features/medication/models/medication.dart';
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

// ── Fixtures ──────────────────────────────────────────────────────────────────

Medication _lisinopril() => Medication(
  id: 'med-1',
  userId: 'u1',
  name: 'Lisinopril',
  dosageAmount: 10,
  dosageUnit: 'mg',
  frequency: 'Once daily',
  color: const Color(0xFF4E84E5),
  createdAt: DateTime(2026, 1, 1),
);

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
      const EditMedicationPayload(
        medicationId: '',
        name: '',
        dosageAmount: 0,
        dosageUnit: 'mg',
        frequency: '',
        color: Colors.white,
        daysOfWeek: [],
        remindersToUpsert: [],
        remindersToDelete: [],
      ),
    );
  });

  group('Edit / Delete Medication Journey (US07)', () {
    late MockMedicationRepository mockMedRepo;

    setUp(() {
      mockMedRepo = MockMedicationRepository();
      when(
        () => mockMedRepo.fetchMedications(),
      ).thenAnswer((_) async => [_lisinopril()]);
      when(() => mockMedRepo.fetchAllReminders()).thenAnswer((_) async => []);
      when(
        () => mockMedRepo.fetchRemindersForMedication(any()),
      ).thenAnswer((_) async => []);
      when(() => mockMedRepo.editMedication(any())).thenAnswer((_) async {});
      when(() => mockMedRepo.deleteMedication(any())).thenAnswer((_) async {});
    });

    testWidgets('US07: MEDS tab shows existing medication card', (
      tester,
    ) async {
      await _bootApp(tester, mockMedRepo: mockMedRepo);

      await tester.tap(find.text('MEDS'));
      await tester.pumpAndSettle();

      expect(find.text('Lisinopril'), findsOneWidget);
    });

    testWidgets('US07: tapping INFO expands card and shows EDITAR', (
      tester,
    ) async {
      await _bootApp(tester, mockMedRepo: mockMedRepo);

      await tester.tap(find.text('MEDS'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('INFO'));
      await tester.pumpAndSettle();

      expect(find.text('EDITAR'), findsOneWidget);
      expect(find.text('ELIMINAR'), findsOneWidget);
      expect(find.text('FECHAR'), findsOneWidget);
    });

    testWidgets(
      'US07: tapping EDITAR opens edit screen with pre-filled medication name',
      (tester) async {
        await _bootApp(tester, mockMedRepo: mockMedRepo);

        await tester.tap(find.text('MEDS'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('INFO'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('EDITAR'));
        await tester.pumpAndSettle();

        // On EditMedicationScreen — name is pre-filled
        expect(find.text('Editar medicação'), findsOneWidget);
        expect(find.text('Lisinopril'), findsOneWidget);
      },
    );

    testWidgets(
      'US07: editing medication name and saving shows success snackbar',
      (tester) async {
        await _bootApp(tester, mockMedRepo: mockMedRepo);

        await tester.tap(find.text('MEDS'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('INFO'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('EDITAR'));
        await tester.pumpAndSettle();

        // Edit the name field
        await tester.enterText(
          find.byKey(const Key('edit_med_name_field')),
          'Lisinopril XL',
        );
        await tester.pump();

        // Save
        await tester.tap(find.byKey(const Key('edit_med_save_button')));
        await tester.pumpAndSettle();

        expect(
          find.text('Medicamento atualizado com sucesso!'),
          findsOneWidget,
        );
      },
    );

    testWidgets('US07: after successful edit, screen pops back to MEDS tab', (
      tester,
    ) async {
      await _bootApp(tester, mockMedRepo: mockMedRepo);

      await tester.tap(find.text('MEDS'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('INFO'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('EDITAR'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('edit_med_name_field')),
        'Lisinopril XL',
      );
      await tester.pump();

      await tester.tap(find.byKey(const Key('edit_med_save_button')));
      await tester.pumpAndSettle();

      // Screen popped — now back on MEDS tab which shows the nav bar
      expect(find.text('MEDS'), findsOneWidget);
      expect(find.text('Editar medicação'), findsNothing);
    });

    testWidgets('US07: tapping ELIMINAR shows confirm dialog', (tester) async {
      await _bootApp(tester, mockMedRepo: mockMedRepo);

      await tester.tap(find.text('MEDS'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('INFO'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('ELIMINAR').first);
      await tester.pumpAndSettle();

      expect(find.text('Eliminar medicamento?'), findsOneWidget);
    });
  });
}

class _MockStreamHandler extends MockStreamHandler {
  @override
  void onListen(Object? arguments, MockStreamHandlerEventSink events) {}

  @override
  void onCancel(Object? arguments) {}
}
