import 'package:clinic_go/features/auth/domain/auth_service.dart';
import 'package:clinic_go/features/medication/data/calendar_repository.dart';
import 'package:clinic_go/features/medication/data/medication_repository.dart';
import 'package:clinic_go/features/medication/data/dose_log_repository.dart';
import 'package:clinic_go/features/medication/models/medication.dart';
import 'package:clinic_go/features/medication/models/medication_reminder.dart';
import 'package:clinic_go/features/medication/presentation/views/dose_logging_screen.dart';
import 'package:clinic_go/features/medication/services/dose_scheduling_service.dart';
import 'package:clinic_go/features/medication/services/local_notification_gateway.dart';
import 'package:clinic_go/features/medication/services/pending_notification_store.dart';
import 'package:clinic_go/features/medication/services/missed_dose_notification_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:get_it/get_it.dart';
import 'package:clinic_go/main.dart' as app;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mocktail/mocktail.dart';
import 'package:intl/intl.dart';

import '../helpers/medication_mocks.dart';

class MockMedicationRepository extends Mock implements MedicationRepository {}

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockAuthService extends Mock implements AuthService {}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Missed Medication Journey Integration Test', () {
    late MockMedicationRepository mockMedRepo;
    late InMemoryDoseLogRepository mockLogRepo;

    setUp(() async {
      mockMedRepo = MockMedicationRepository();
      mockLogRepo = InMemoryDoseLogRepository();

      final getIt = GetIt.instance;
      await getIt.reset();
      getIt.allowReassignment = true;

      // Mock AppLinks
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

      SharedPreferences.setMockInitialValues({});

      try {
        await Supabase.initialize(
          url: 'https://test.supabase.co',
          anonKey: 'test-anon-key',
        );
      } catch (_) {}
    });

    testWidgets('Full Journey: Dashboard -> Log Overdue Dose', (tester) async {
      final now = DateTime.now();
      // Setup an overdue dose within the 2-hour window (e.g., 45 mins ago)
      final overdueTime = now.subtract(const Duration(minutes: 45));
      final overdueStr = DateFormat('HH:mm:ss').format(overdueTime);

      final med = Medication(
        id: 'med-123',
        userId: 'user-123',
        name: 'Lisinopril',
        dosage: '10mg',
        color: Colors.blue,
        createdAt: now.subtract(const Duration(days: 1)),
      );
      final reminder = MedicationReminder(
        id: 'rem-1',
        medicationId: 'med-123',
        reminderTime: overdueStr,
        daysOfWeek: const [
          'monday',
          'tuesday',
          'wednesday',
          'thursday',
          'friday',
          'saturday',
          'sunday',
        ],
      );

      when(() => mockMedRepo.fetchMedications()).thenAnswer((_) async => [med]);
      when(
        () => mockMedRepo.fetchAllReminders(),
      ).thenAnswer((_) async => [reminder]);

      final getIt = GetIt.instance;
      final navigatorKey = GlobalKey<NavigatorState>();

      // Register mocks BEFORE building the app
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
      getIt.registerSingleton<DoseLogRepository>(mockLogRepo);
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

      await tester.pumpWidget(app.ClinicGO(navigatorKey: navigatorKey));
      // Give it time to initialize and run loadNextDose
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Navigate to Home tab (index 2)
      await tester.tap(find.byIcon(Icons.home_outlined));
      await tester.pumpAndSettle();

      // Verify Overdue dose is visible
      expect(find.text('Overdue dose'), findsOneWidget);
      expect(find.text('Lisinopril • 10mg'), findsOneWidget);

      // Tap Log Overdue Dose
      await tester.tap(find.text('Log Overdue Dose'));
      await tester.pumpAndSettle();

      // Verify we are on DoseLoggingScreen
      expect(find.byType(DoseLoggingScreen), findsOneWidget);

      // Log as taken
      await tester.tap(find.text('Mark as Taken'));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Verify we returned to Dashboard/MainScreen
      expect(find.text('Welcome to ClinicGO!'), findsOneWidget);

      // The dose for tomorrow should now be the "Upcoming" dose
      expect(find.text('Upcoming dose'), findsOneWidget);
      expect(find.text('Overdue dose'), findsNothing);
    });
  });
}

class _MockStreamHandler extends MockStreamHandler {
  @override
  void onListen(Object? arguments, MockStreamHandlerEventSink events) {}
  @override
  void onCancel(Object? arguments) {}
}
