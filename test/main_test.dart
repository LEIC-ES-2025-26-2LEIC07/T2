import 'package:clinic_go/features/calendar/data/calendar_repository.dart';
import 'package:clinic_go/features/medication/data/medication_repository.dart';
import 'package:clinic_go/features/medication/data/dose_log_repository.dart';
import 'package:clinic_go/features/medication/models/notification_payload.dart';
import 'package:clinic_go/features/medication/services/dose_scheduling_service.dart';
import 'package:clinic_go/features/medication/services/missed_dose_notification_controller.dart';
import 'package:clinic_go/features/medication/services/pending_notification_store.dart';
import 'package:clinic_go/features/home/presentation/views/main_screen.dart';
import 'package:clinic_go/features/auth/domain/auth_service.dart';
import 'package:clinic_go/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'helpers/mocks.dart';
import 'helpers/medication_mocks.dart';

class MockMedicationRepository extends Mock implements MedicationRepository {}

void main() {
  late MemoryNotificationGateway notificationGateway;
  late InMemoryDoseLogRepository doseLogRepository;
  late MockMedicationRepository medicationRepository;
  late MissedDoseNotificationController controller;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await GetIt.I.reset();

    notificationGateway = MemoryNotificationGateway();
    doseLogRepository = InMemoryDoseLogRepository();
    medicationRepository = MockMedicationRepository();

    // Stub medication methods to return empty lists by default
    when(
      () => medicationRepository.fetchMedications(),
    ).thenAnswer((_) async => []);
    when(
      () => medicationRepository.fetchAllReminders(),
    ).thenAnswer((_) async => []);

    controller = MissedDoseNotificationController(
      notificationGateway: notificationGateway,
      doseLogRepository: doseLogRepository,
      pendingNotificationStore: const PendingNotificationStore(),
    );

    GetIt.I.registerSingleton<MedicationRepository>(medicationRepository);
    GetIt.I.registerSingleton<DoseLogRepository>(doseLogRepository);
    GetIt.I.registerSingleton<DoseSchedulingService>(
      const DoseSchedulingService(),
    );
    GetIt.I.registerSingleton<MissedDoseNotificationController>(controller);
    GetIt.I.registerSingleton<AuthService>(AlwaysSuccessAuth());
    GetIt.I.registerSingleton<CalendarRepository>(EmptyCalendarRepository());
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  group('ClinicGO', () {
    testWidgets('configures the main Material app shell', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const ClinicGO());
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.title, 'ClinicGO');
      expect(materialApp.debugShowCheckedModeBanner, isFalse);
      expect(materialApp.theme?.useMaterial3, isTrue);
      expect(find.byType(MainScreen), findsOneWidget);
    });

    testWidgets('renders home screen with quick action boxes', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const ClinicGO());
      await tester.pumpAndSettle();
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.text('Registar sintoma'), findsOneWidget);
      expect(find.text('Histórico'), findsOneWidget);
    });

    testWidgets('tapping MEDS nav item shows medications screen', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const ClinicGO());
      await tester.pumpAndSettle();
      await tester.tap(find.text('MEDS'));
      await tester.pumpAndSettle();
      expect(find.text('Nenhum medicamento'), findsOneWidget);
    });

    testWidgets(
      'navigates to initial notification route from payload on startup',
      (tester) async {
        final navigatorKey = GlobalKey<NavigatorState>();
        const payload = NotificationPayload(
          route: '/home',
          status: 'overdue',
          doseId: 'test-dose',
        );

        await tester.pumpWidget(
          ClinicGO(
            navigatorKey: navigatorKey,
            initialNotificationPayload: payload,
          ),
        );
        await tester.pumpAndSettle();

        expect(navigatorKey.currentState?.canPop(), isTrue);
      },
    );

    testWidgets('shows Plano de hoje section after loading', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const ClinicGO());
      await tester.pumpAndSettle();
      expect(find.text('Plano de hoje'), findsOneWidget);
      expect(find.text('Sem doses agendadas para hoje.'), findsOneWidget);
    });
  });

  group('ClinicGO app shell', () {
    Future<void> pumpApp(WidgetTester tester) async {
      await tester.pumpWidget(const ClinicGO());
      await tester.pumpAndSettle();
    }

    testWidgets('renders Home tab by default', (tester) async {
      await pumpApp(tester);
      expect(find.text('ClinicGO'), findsOneWidget);
    });

    testWidgets('Profile tab shows login form when not logged in', (
      tester,
    ) async {
      await pumpApp(tester);
      await tester.tap(find.byIcon(Icons.person_outline));
      await tester.pumpAndSettle();
      expect(find.text('Forgot password'), findsOneWidget);
    });

    testWidgets('Profile tab shows "Create account" link', (tester) async {
      await pumpApp(tester);
      await tester.tap(find.byIcon(Icons.person_outline));
      await tester.pumpAndSettle();
      expect(find.textContaining('Create one now'), findsOneWidget);
    });

    testWidgets('tapping "Create account" link opens SignUpSheet', (
      tester,
    ) async {
      await pumpApp(tester);
      await tester.tap(find.byIcon(Icons.person_outline));
      await tester.pumpAndSettle();

      final createAccountFinder = find.textContaining('Create one now');
      await tester.ensureVisible(createAccountFinder);

      await tester.tap(createAccountFinder);
      await tester.pumpAndSettle();
      expect(find.text('Create account'), findsWidgets);
      expect(find.text('Sign up to start using ClinicGO.'), findsOneWidget);
    });
  });
}
