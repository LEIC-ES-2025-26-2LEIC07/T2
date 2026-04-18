import 'package:clinic_go/features/medication/data/dose_log_repository.dart';
import 'package:clinic_go/features/medication/models/scheduled_dose.dart';
import 'package:clinic_go/features/medication/services/local_notification_gateway.dart';
import 'package:clinic_go/features/medication/services/missed_dose_notification_controller.dart';
import 'package:clinic_go/features/medication/services/pending_notification_store.dart';
import 'package:clinic_go/features/home/presentation/views/main_screen.dart';
import 'package:clinic_go/features/auth/domain/auth_service.dart';
import 'package:clinic_go/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get_it/get_it.dart';
import 'helpers/mocks.dart';

class _MemoryNotificationGateway implements LocalNotificationGateway {
  final List<NotificationRequest> scheduledRequests = [];
  final List<int> cancelledNotificationIds = [];
  @override
  Future<void> cancel(int notificationId) async {
    cancelledNotificationIds.add(notificationId);
  }

  @override
  Future<void> schedule(NotificationRequest request) async {
    scheduledRequests.add(request);
  }
}

class _InMemoryDoseLogRepository implements DoseLogRepository {
  final Set<String> _loggedDoseIds = <String>{};
  @override
  Future<bool> hasDoseLog(String doseId) async =>
      _loggedDoseIds.contains(doseId);
  @override
  Future<void> insertDoseLog({
    required ScheduledDose dose,
    required DoseLogStatus status,
    required DateTime loggedAt,
  }) async {
    _loggedDoseIds.add(dose.id);
  }
}

class _FailingDoseLogRepository implements DoseLogRepository {
  @override
  Future<bool> hasDoseLog(String doseId) async => false;
  @override
  Future<void> insertDoseLog({
    required ScheduledDose dose,
    required DoseLogStatus status,
    required DateTime loggedAt,
  }) {
    throw StateError('insert failed');
  }
}

void main() {
  late _MemoryNotificationGateway notificationGateway;
  late _InMemoryDoseLogRepository doseLogRepository;
  late MissedDoseNotificationController controller;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await GetIt.I.reset();
    notificationGateway = _MemoryNotificationGateway();
    doseLogRepository = _InMemoryDoseLogRepository();
    controller = MissedDoseNotificationController(
      notificationGateway: notificationGateway,
      doseLogRepository: doseLogRepository,
      pendingNotificationStore: const PendingNotificationStore(),
    );

    GetIt.I.registerSingleton<MissedDoseNotificationController>(controller);
    GetIt.I.registerSingleton<AuthService>(AlwaysSuccessAuth());
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

    testWidgets('renders the home screen search bar', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const ClinicGO());
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.text('O que precisas?'), findsOneWidget);
      expect(find.text('Open overdue dose'), findsOneWidget);
    });

    testWidgets(
      'deep-links to the dose logging screen with overdue messaging',
      (WidgetTester tester) async {
        await tester.pumpWidget(const ClinicGO());
        await tester.tap(find.text('Open overdue dose'));
        await tester.pumpAndSettle();
        expect(find.text('Dose Logging'), findsOneWidget);
        expect(
          find.text(
            'This dose is overdue. Please log whether it was taken or skipped.',
          ),
          findsOneWidget,
        );
        expect(find.text('Mark as Taken'), findsOneWidget);
      },
    );

    testWidgets('shows an error snackbar if dose logging fails', (
      WidgetTester tester,
    ) async {
      controller = MissedDoseNotificationController(
        notificationGateway: notificationGateway,
        doseLogRepository: _FailingDoseLogRepository(),
        pendingNotificationStore: const PendingNotificationStore(),
      );
      GetIt.I.unregister<MissedDoseNotificationController>();
      GetIt.I.registerSingleton<MissedDoseNotificationController>(controller);

      await tester.pumpWidget(const ClinicGO());
      await tester.tap(find.text('Open overdue dose'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mark as Taken'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        find.text('We could not save this dose right now. Please try again.'),
        findsOneWidget,
      );
    });
  });

  group('ClinicGO app shell', () {
    Future<void> pumpApp(WidgetTester tester) async {
      await tester.pumpWidget(const ClinicGO());
      await tester.pumpAndSettle();
    }

    testWidgets('renders Home tab by default', (tester) async {
      await pumpApp(tester);
      expect(find.text('Bem-vindo à ClinicGO!'), findsOneWidget);
    });

    testWidgets('Profile tab shows login form when not logged in', (
      tester,
    ) async {
      await pumpApp(tester);
      await tester.tap(find.byIcon(Icons.person_outline));
      await tester.pumpAndSettle();
      expect(find.text('Continuar com Apple'), findsOneWidget);
    });

    testWidgets('Profile tab shows "Criar conta" link', (tester) async {
      await pumpApp(tester);
      await tester.tap(find.byIcon(Icons.person_outline));
      await tester.pumpAndSettle();
      expect(find.textContaining('Cria uma agora'), findsOneWidget);
    });

    testWidgets('tapping "Criar conta" link opens SignUpSheet', (tester) async {
      await pumpApp(tester);
      await tester.tap(find.byIcon(Icons.person_outline));
      await tester.pumpAndSettle();

      final createAccountFinder = find.textContaining('Cria uma agora');
      await tester.ensureVisible(createAccountFinder);

      await tester.tap(createAccountFinder);
      await tester.pumpAndSettle();
      expect(find.text('Criar conta'), findsWidgets);
      expect(
        find.text('Regista-te para começar a usar o ClinicGO.'),
        findsOneWidget,
      );
    });
  });
}
