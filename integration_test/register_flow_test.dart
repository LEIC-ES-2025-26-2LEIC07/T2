import 'dart:async';

import 'package:clinic_go/features/auth/domain/auth_service.dart';
import 'package:clinic_go/features/calendar/data/calendar_repository.dart';
import 'package:clinic_go/features/medication/data/dose_log_repository.dart';
import 'package:clinic_go/features/medication/data/medication_repository.dart';
import 'package:clinic_go/features/medication/models/medication.dart';
import 'package:clinic_go/features/medication/models/medication_reminder.dart';
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

class _MockSupabaseClient extends Mock implements SupabaseClient {}

class _EmptyMedicationRepo implements MedicationRepository {
  @override
  Future<SavedMedicationResult> addMedication(AddMedicationPayload p) async =>
      const SavedMedicationResult(medicationId: 'id', reminders: []);

  @override
  Future<void> editMedication(EditMedicationPayload payload) async {}

  @override
  Future<void> deleteMedication(String id) async {}

  @override
  Future<List<MedicationReminder>> fetchAllReminders() async => [];

  @override
  Future<List<Medication>> fetchMedications() async => [];

  @override
  Future<List<MedicationReminder>> fetchRemindersForMedication(
    String medicationId,
  ) async => [];
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Register flow', () {
    setUp(() async {
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
    });

    tearDown(() async {
      await GetIt.instance.reset();
    });

    testWidgets(
      'fills registration form and navigates to main screen on success',
      (tester) async {
        final authService = _InMemoryAuthService();

        final getIt = GetIt.instance;
        getIt.registerSingleton<AuthService>(authService);
        getIt.registerSingleton<SupabaseClient>(_MockSupabaseClient());
        getIt.registerSingleton<MedicationRepository>(_EmptyMedicationRepo());
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

        await tester.pumpWidget(
          app.ClinicGO(navigatorKey: GlobalKey<NavigatorState>()),
        );
        await tester.pumpAndSettle();

        // App boots unauthenticated → LoginScreen
        expect(find.text('Entrar'), findsOneWidget);

        // Tap "CRIAR" to go to RegisterScreen
        await tester.tap(find.text('CRIAR'));
        await tester.pumpAndSettle();

        expect(find.text('Criar conta'), findsOneWidget);

        // Fill in registration fields
        await tester.enterText(
          find.widgetWithText(TextField, 'ex: Maria Silva'),
          'Maria Silva',
        );
        await tester.enterText(
          find.widgetWithText(TextField, 'o.teu@email.pt'),
          'maria@example.com',
        );
        await tester.enterText(
          find.widgetWithText(TextField, 'Mínimo 8 caracteres'),
          'password123',
        );
        await tester.enterText(
          find.widgetWithText(TextField, 'Repete a password'),
          'password123',
        );
        await tester.pump();

        // Submit
        await tester.tap(find.textContaining('Concluir registo'));
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // After successful sign-up, the app navigates to the main screen
        expect(find.text('Plano de hoje'), findsOneWidget);
      },
    );
  });
}

class _InMemoryAuthService implements AuthService {
  bool _isLoggedIn = false;
  String _email = '';
  final StreamController<bool> _ctrl = StreamController<bool>.broadcast();

  @override
  Stream<bool> get authStateChanges async* {
    yield _isLoggedIn;
    yield* _ctrl.stream;
  }

  @override
  bool get isLoggedIn => _isLoggedIn;

  @override
  String? get currentUserEmail => _isLoggedIn ? _email : null;

  @override
  Map<String, dynamic> get currentUserMetadata => const {};

  @override
  Future<void> signIn({required String email, required String password}) async {
    _email = email;
    _isLoggedIn = true;
    _ctrl.add(true);
  }

  @override
  Future<void> signUp({required String email, required String password}) async {
    _email = email;
    _isLoggedIn = true;
    _ctrl.add(true);
  }

  @override
  Future<void> signOut() async {
    _isLoggedIn = false;
    _ctrl.add(false);
  }

  @override
  Future<void> resetPassword(String email) async {}

  @override
  Future<void> updateProfile({
    required String email,
    required Map<String, dynamic> metadata,
  }) async {}
}

class _MockStreamHandler extends MockStreamHandler {
  @override
  void onListen(Object? arguments, MockStreamHandlerEventSink events) {}
  @override
  void onCancel(Object? arguments) {}
}
