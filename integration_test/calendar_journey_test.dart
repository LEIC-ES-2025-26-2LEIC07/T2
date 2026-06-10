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
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Calendar Journey (US04)', () {
    testWidgets('US04: navigating to PLAN shows Calendar with month header', (
      tester,
    ) async {
      await _bootApp(tester);

      await tester.tap(find.text('PLANO'));
      await tester.pumpAndSettle();

      // PLANO appears in nav bar and AppBar
      expect(find.text('PLANO'), findsWidgets);

      // Month header formatted as e.g. "JUN 2026"
      const ptMonths = [
        'JAN',
        'FEV',
        'MAR',
        'ABR',
        'MAI',
        'JUN',
        'JUL',
        'AGO',
        'SET',
        'OUT',
        'NOV',
        'DEZ',
      ];
      final now = DateTime.now();
      final expectedHeader = '${ptMonths[now.month - 1]} ${now.year}';
      expect(find.text(expectedHeader), findsOneWidget);
    });

    testWidgets('US04: calendar shows legend items', (tester) async {
      await _bootApp(tester);

      await tester.tap(find.text('PLANO'));
      await tester.pumpAndSettle();

      expect(find.text('Todas tomadas'), findsOneWidget);
      expect(find.text('Parcial'), findsOneWidget);
      expect(find.text('Falhadas'), findsOneWidget);
      expect(find.text('Próximas'), findsOneWidget);
    });

    testWidgets(
      'US04: tapping a day with no activity shows bottom sheet message',
      (tester) async {
        await _bootApp(tester);

        await tester.tap(find.text('PLANO'));
        await tester.pumpAndSettle();

        // Tap the first day cell in the grid — day '1' of the current month.
        // Use firstMatchingWidget to avoid collision with any other '1' text.
        await tester.tap(find.text('1').first);
        await tester.pumpAndSettle();

        expect(find.text('Sem doses para este dia.'), findsOneWidget);
      },
    );

    testWidgets('US04: month navigation arrows are present', (tester) async {
      await _bootApp(tester);

      await tester.tap(find.text('PLANO'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.chevron_left), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('US04: tapping next month arrow updates the header', (
      tester,
    ) async {
      await _bootApp(tester);

      await tester.tap(find.text('PLANO'));
      await tester.pumpAndSettle();

      const ptMonths = [
        'JAN',
        'FEV',
        'MAR',
        'ABR',
        'MAI',
        'JUN',
        'JUL',
        'AGO',
        'SET',
        'OUT',
        'NOV',
        'DEZ',
      ];
      final now = DateTime.now();
      final nextMonth = DateTime(now.year, now.month + 1);
      final nextHeader = '${ptMonths[nextMonth.month - 1]} ${nextMonth.year}';

      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pumpAndSettle();

      expect(find.text(nextHeader), findsOneWidget);
    });
  });
}

class _MockStreamHandler extends MockStreamHandler {
  @override
  void onListen(Object? arguments, MockStreamHandlerEventSink events) {}

  @override
  void onCancel(Object? arguments) {}
}
