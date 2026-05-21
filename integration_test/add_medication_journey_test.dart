import 'dart:async';

import 'package:clinic_go/features/auth/domain/auth_service.dart';
import 'package:clinic_go/features/calendar/data/calendar_repository.dart';
import 'package:clinic_go/features/medication/data/dose_log_repository.dart';
import 'package:clinic_go/features/medication/data/medication_repository.dart';
import 'package:clinic_go/features/medication/services/dose_scheduling_service.dart';
import 'package:clinic_go/features/medication/services/local_notification_gateway.dart';
import 'package:clinic_go/features/medication/services/missed_dose_notification_controller.dart';
import 'package:clinic_go/features/medication/services/pending_notification_store.dart';
import 'package:clinic_go/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../test/helpers/medication_mocks.dart';

class MockMedicationRepository extends Mock implements MedicationRepository {}

class MockAuthService extends Mock implements AuthService {}

class MockSupabaseClient extends Mock implements SupabaseClient {}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(
      const AddMedicationPayload(
        name: '',
        dosageAmount: 0,
        dosageUnit: 'mg',
        frequency: 'Daily',
        color: Colors.blue,
        reminderTimes: [],
        daysOfWeek: [],
      ),
    );
  });

  group('Add Medication Journey', () {
    late MockMedicationRepository mockMedRepo;

    setUp(() async {
      mockMedRepo = MockMedicationRepository();

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
      ).thenAnswer((_) => Stream.fromIterable([true]));
      when(() => mockAuth.isLoggedIn).thenReturn(true);
      when(() => mockAuth.currentUserEmail).thenReturn('user@example.com');
      when(() => mockAuth.currentUserMetadata).thenReturn(const {});

      when(() => mockMedRepo.fetchMedications()).thenAnswer((_) async => []);
      when(() => mockMedRepo.fetchAllReminders()).thenAnswer((_) async => []);
      when(() => mockMedRepo.addMedication(any())).thenAnswer(
        (_) async =>
            const SavedMedicationResult(medicationId: 'new-id', reminders: []),
      );

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
    });

    testWidgets('navigates to add form, submits, and returns to list', (
      tester,
    ) async {
      await tester.pumpWidget(
        app.ClinicGO(navigatorKey: GlobalKey<NavigatorState>()),
      );
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Navigate to Medications tab
      await tester.tap(find.byIcon(Icons.medication_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Medicação'), findsOneWidget);

      // Open AddMedicationScreen
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Fill in the medication name
      await tester.enterText(
        find.widgetWithText(TextField, 'ex: Metformina'),
        'Paracetamol',
      );
      await tester.pump();

      // Fill in the dosage amount
      await tester.enterText(find.widgetWithText(TextField, 'ex: 500'), '500');
      await tester.pump();

      // Submit the form
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // addMedication was called on the repository
      verify(() => mockMedRepo.addMedication(any())).called(1);

      // Back on the medications list
      expect(find.text('Medicação'), findsOneWidget);
    });
  });
}

class _MockStreamHandler extends MockStreamHandler {
  @override
  void onListen(Object? arguments, MockStreamHandlerEventSink events) {}

  @override
  void onCancel(Object? arguments) {}
}
