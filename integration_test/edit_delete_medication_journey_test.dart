import 'package:clinic_go/features/auth/domain/auth_service.dart';
import 'package:clinic_go/features/calendar/data/calendar_repository.dart';
import 'package:clinic_go/features/medication/data/dose_log_repository.dart';
import 'package:clinic_go/features/medication/data/medication_repository.dart';
import 'package:clinic_go/features/medication/models/medication.dart';
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

final _testMed = Medication(
  id: 'med-1',
  userId: 'user-123',
  name: 'Ibuprofeno',
  dosageAmount: 400,
  dosageUnit: 'mg',
  color: Colors.blue,
  createdAt: DateTime(2025),
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(
      const EditMedicationPayload(
        medicationId: '',
        name: '',
        dosageAmount: 0,
        dosageUnit: 'mg',
        frequency: 'Daily',
        color: Colors.blue,
        daysOfWeek: [],
        remindersToUpsert: [],
        remindersToDelete: [],
      ),
    );
  });

  group('Edit & Delete Medication Journey', () {
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

      when(
        () => mockMedRepo.fetchMedications(),
      ).thenAnswer((_) async => [_testMed]);
      when(() => mockMedRepo.fetchAllReminders()).thenAnswer((_) async => []);
      when(
        () => mockMedRepo.fetchRemindersForMedication('med-1'),
      ).thenAnswer((_) async => []);
      when(() => mockMedRepo.editMedication(any())).thenAnswer((_) async {});
      when(
        () => mockMedRepo.deleteMedication('med-1'),
      ).thenAnswer((_) async {});

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

    Future<void> goToMedsTab(WidgetTester tester) async {
      await tester.pumpWidget(
        app.ClinicGO(navigatorKey: GlobalKey<NavigatorState>()),
      );
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await tester.tap(find.byIcon(Icons.medication_outlined));
      await tester.pumpAndSettle();
    }

    testWidgets('expand card, edit medication, and save', (tester) async {
      await goToMedsTab(tester);

      // Expand the medication card
      await tester.tap(find.text('INFO'));
      await tester.pumpAndSettle();

      // Open EditMedicationScreen
      await tester.tap(find.text('EDITAR'));
      await tester.pumpAndSettle();

      expect(find.text('Editar medicação'), findsOneWidget);

      // Save without changes — just confirm the form submits
      await tester.tap(find.text('Guardar alterações'));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      verify(() => mockMedRepo.editMedication(any())).called(1);
    });

    testWidgets('expand card, confirm delete, and see success snackbar', (
      tester,
    ) async {
      await goToMedsTab(tester);

      // Expand the medication card
      await tester.tap(find.text('INFO'));
      await tester.pumpAndSettle();

      // Tap ELIMINAR to open confirmation dialog
      await tester.tap(find.text('ELIMINAR'));
      await tester.pumpAndSettle();

      expect(find.text('Eliminar medicamento?'), findsOneWidget);

      // Confirm deletion — tap the last 'ELIMINAR' (dialog button, not card button)
      await tester.tap(find.text('ELIMINAR').last);
      await tester.pumpAndSettle();

      verify(() => mockMedRepo.deleteMedication('med-1')).called(1);
      expect(find.textContaining('eliminado com sucesso'), findsOneWidget);
    });
  });
}

class _MockStreamHandler extends MockStreamHandler {
  @override
  void onListen(Object? arguments, MockStreamHandlerEventSink events) {}
  @override
  void onCancel(Object? arguments) {}
}
