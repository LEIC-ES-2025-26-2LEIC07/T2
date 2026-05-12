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

  group('Notification Flow Integration Test', () {
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

    testWidgets(
      'Verify navigation to DoseLoggingScreen from notification-like action',
      (WidgetTester tester) async {
        final now = DateTime.now();
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

        when(
          () => mockMedRepo.fetchMedications(),
        ).thenAnswer((_) async => [med]);
        when(
          () => mockMedRepo.fetchAllReminders(),
        ).thenAnswer((_) async => [reminder]);

        final getIt = GetIt.instance;
        final navigatorKey = GlobalKey<NavigatorState>();

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
        await tester.pumpAndSettle(const Duration(seconds: 1));

        await tester.tap(find.byIcon(Icons.home_outlined));
        await tester.pumpAndSettle();

        // Verify we are on the Home screen
        expect(find.text('Welcome to ClinicGO!'), findsOneWidget);
        expect(
          find.text('Upcoming dose'),
          findsNothing,
        ); // It's overdue, not "upcoming"
        expect(find.text('Overdue dose'), findsOneWidget);

        // Find the button that simulates opening an overdue dose (notification behavior)
        final openDoseButton = find.text('Open overdue dose');
        expect(openDoseButton, findsOneWidget);

        // Tap the button
        await tester.tap(openDoseButton);

        // Wait for navigation animation
        await tester.pumpAndSettle();

        // Verify we have navigated to the DoseLoggingScreen
        expect(find.byType(DoseLoggingScreen), findsOneWidget);
        expect(find.text('Lisinopril'), findsOneWidget);
        expect(find.textContaining('10mg'), findsOneWidget);
        expect(find.text('Dose Logging'), findsOneWidget);

        // Verify the "Overdue" status is shown
        expect(
          find.textContaining(RegExp('overdue', caseSensitive: false)),
          findsWidgets,
        );
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
