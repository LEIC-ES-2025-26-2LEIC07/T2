import 'package:clinic_go/features/auth/domain/auth_service.dart';
import 'package:clinic_go/features/medication/data/calendar_repository.dart';
import 'package:clinic_go/features/medication/data/dose_log_repository.dart';
import 'package:clinic_go/features/medication/data/medication_repository.dart';
import 'package:clinic_go/features/medication/services/dose_scheduling_service.dart';
import 'package:clinic_go/features/medication/services/local_notification_gateway.dart';
import 'package:clinic_go/features/medication/services/missed_dose_notification_controller.dart';
import 'package:clinic_go/features/medication/services/pending_notification_store.dart';
import 'package:clinic_go/features/symptoms/presentation/views/log_symptom_screen.dart';
import 'package:clinic_go/features/symptoms/presentation/views/symptom_history_screen.dart';
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

// ── Shared setup ─────────────────────────────────────────────────────────────

Future<void> _bootApp(WidgetTester tester) async {
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

  final mockMedRepo = MockMedicationRepository();
  when(() => mockMedRepo.fetchMedications()).thenAnswer((_) async => []);
  when(() => mockMedRepo.fetchAllReminders()).thenAnswer((_) async => []);

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

  // Go to Home tab
  await tester.tap(find.byIcon(Icons.home_outlined));
  await tester.pumpAndSettle();
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Symptom Log Journey', () {
    testWidgets(
      'User can navigate to Log Symptom screen and see symptom chips',
      (tester) async {
        await _bootApp(tester);

        // Tap "Log Symptom" on Home
        await tester.tap(find.text('Log Symptom'));
        await tester.pumpAndSettle();

        expect(find.byType(LogSymptomScreen), findsOneWidget);
        expect(find.text('How are you feeling?'), findsOneWidget);
        expect(find.text('Headache'), findsOneWidget);
        expect(find.text('Nausea'), findsOneWidget);
      },
    );

    testWidgets('Tapping a chip selects it and enables save', (tester) async {
      await _bootApp(tester);

      await tester.tap(find.text('Log Symptom'));
      await tester.pumpAndSettle();

      // Tap a chip
      await tester.tap(find.text('Fatigue'));
      await tester.pump();

      // Chip should now be selected (ChoiceChip selected state)
      final chip = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, 'Fatigue'),
      );
      expect(chip.selected, isTrue);
    });

    testWidgets('Saving without a signed-in user shows sign-in error banner', (
      tester,
    ) async {
      // Supabase has no current user → currentUserProvider returns null
      await _bootApp(tester);

      await tester.tap(find.text('Log Symptom'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Headache'));
      await tester.pump();

      // Scroll to Save button and tap
      await tester.ensureVisible(find.text('Save symptom'));
      await tester.tap(find.text('Save symptom'));
      await tester.pump();

      expect(find.textContaining('Sign in'), findsOneWidget);
    });

    testWidgets('User can navigate to Symptom History and see empty state', (
      tester,
    ) async {
      await _bootApp(tester);

      await tester.tap(find.text('Symptom History'));
      await tester.pumpAndSettle();

      expect(find.byType(SymptomHistoryScreen), findsOneWidget);
      // No user signed in → fetchSymptomLogs returns [] → empty state
      expect(find.textContaining('No symptom logs yet'), findsOneWidget);
    });

    testWidgets('Back navigation from Log Symptom returns to Home', (
      tester,
    ) async {
      await _bootApp(tester);

      await tester.tap(find.text('Log Symptom'));
      await tester.pumpAndSettle();

      expect(find.byType(LogSymptomScreen), findsOneWidget);

      final NavigatorState navigator = tester.state(
        find.byType(Navigator).last,
      );
      navigator.pop();
      await tester.pumpAndSettle();

      expect(find.text('Welcome to ClinicGO!'), findsOneWidget);
    });
  });
}

class _MockStreamHandler extends MockStreamHandler {
  @override
  void onListen(Object? arguments, MockStreamHandlerEventSink events) {}
  @override
  void onCancel(Object? arguments) {}
}
