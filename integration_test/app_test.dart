import 'package:clinic_go/features/auth/domain/auth_service.dart';
import 'package:clinic_go/features/calendar/data/calendar_repository.dart';
import 'package:clinic_go/features/medication/data/medication_repository.dart';
import 'package:clinic_go/features/medication/data/dose_log_repository.dart';
import 'package:clinic_go/features/medication/services/missed_dose_notification_controller.dart';
import 'package:clinic_go/features/medication/services/local_notification_gateway.dart';
import 'package:clinic_go/features/medication/services/pending_notification_store.dart';
import 'package:clinic_go/features/medication/services/dose_scheduling_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:get_it/get_it.dart';
import 'package:clinic_go/main.dart' as app;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mocktail/mocktail.dart';

import '../test/helpers/medication_mocks.dart';

class MockMedicationRepository extends Mock implements MedicationRepository {}

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockAuthService extends Mock implements AuthService {}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Integration Test', () {
    testWidgets('boots the app and keeps core components wired together', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});

      // Mock AppLinks
      tester.binding.defaultBinaryMessenger.setMockStreamHandler(
        const EventChannel('com.llfbandit.app_links/events'),
        _MockStreamHandler(),
      );
      tester.binding.defaultBinaryMessenger.setMockStreamHandler(
        const EventChannel('com.llfbandit.app_links/messages'),
        _MockStreamHandler(),
      );

      final getIt = GetIt.instance;
      await getIt.reset();
      getIt.allowReassignment = true;

      try {
        await Supabase.initialize(
          url: 'https://test.supabase.co',
          anonKey: 'test-anon-key',
        );
      } catch (_) {}

      final mockAuth = MockAuthService();
      when(
        () => mockAuth.authStateChanges,
      ).thenAnswer((_) => Stream.fromIterable([false]));
      when(() => mockAuth.isLoggedIn).thenReturn(false);

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

      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.text('Entrar'), findsOneWidget);
    });
  });
}

class _MockStreamHandler extends MockStreamHandler {
  @override
  void onListen(Object? arguments, MockStreamHandlerEventSink events) {}
  @override
  void onCancel(Object? arguments) {}
}
