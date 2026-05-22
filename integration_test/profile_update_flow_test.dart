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

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Profile update flow', () {
    late _InMemoryAuthService authService;

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

      authService = _InMemoryAuthService(
        email: 'old@example.com',
        password: 'secret123',
        metadata: const {
          'name': 'USER_TEST',
          'birth_date': '1990-01-02',
          'phone': '910000000',
          'preferences': 'Morning appointments',
        },
      );

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
    });

    tearDown(() async {
      authService.dispose();
      await GetIt.instance.reset();
    });

    testWidgets(
      'authenticates, edits profile, and reloads persisted metadata',
      (tester) async {
        await tester.pumpWidget(
          app.ClinicGO(navigatorKey: GlobalKey<NavigatorState>()),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextField, 'Email'),
          authService.email,
        );
        await tester.enterText(
          find.widgetWithText(TextField, 'Password'),
          'secret123',
        );
        await tester.tap(find.text('Entrar'));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.person_outline));
        await tester.pumpAndSettle();
        expect(find.text('USER_TEST'), findsWidgets);

        await tester.tap(find.text('Edit'));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextField, 'Nome'),
          'Maria Silva',
        );
        await tester.enterText(
          find.widgetWithText(TextField, 'Email'),
          'maria@example.com',
        );
        await tester.enterText(
          find.widgetWithText(TextField, 'Telefone'),
          '919999999',
        );
        await tester.enterText(
          find.widgetWithText(TextField, 'Preferências'),
          'Afternoon appointments',
        );
        final saveButton = find.widgetWithText(ElevatedButton, 'Save');
        await tester.ensureVisible(saveButton);
        await tester.tap(saveButton);
        await tester.pumpAndSettle();

        expect(authService.email, 'maria@example.com');
        expect(authService.currentUserMetadata['name'], 'Maria Silva');
        expect(authService.currentUserMetadata['birth_date'], '1990-01-02');
        expect(authService.currentUserMetadata['phone'], '919999999');
        expect(
          authService.currentUserMetadata['preferences'],
          'Afternoon appointments',
        );
        expect(find.text('Profile updated successfully.'), findsOneWidget);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpWidget(
          app.ClinicGO(navigatorKey: GlobalKey<NavigatorState>()),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.person_outline));
        await tester.pumpAndSettle();
        expect(find.text('MARIA SILVA'), findsOneWidget);
        expect(find.text('maria@example.com'), findsOneWidget);
        expect(find.text('Afternoon appointments'), findsOneWidget);
      },
    );
  });
}

class _InMemoryAuthService implements AuthService {
  _InMemoryAuthService({
    required String email,
    required String password,
    required Map<String, dynamic> metadata,
  }) : _email = email,
       _password = password,
       _metadata = Map<String, dynamic>.from(metadata);

  final String _password;
  final StreamController<bool> _authStateController =
      StreamController<bool>.broadcast();

  String _email;
  bool _isLoggedIn = false;
  Map<String, dynamic> _metadata;

  String get email => _email;

  @override
  String? get currentUserEmail => _isLoggedIn ? _email : null;

  @override
  Map<String, dynamic> get currentUserMetadata =>
      _isLoggedIn ? Map<String, dynamic>.unmodifiable(_metadata) : const {};

  @override
  bool get isLoggedIn => _isLoggedIn;

  @override
  Stream<bool> get authStateChanges async* {
    yield _isLoggedIn;
    yield* _authStateController.stream;
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    if (email != _email || password != _password) {
      throw const AuthServiceException(
        AuthFailureType.validation,
        'Invalid credentials.',
      );
    }

    _isLoggedIn = true;
    _authStateController.add(true);
  }

  @override
  Future<void> signUp({
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> signOut() async {
    _isLoggedIn = false;
    _authStateController.add(false);
  }

  @override
  Future<void> resetPassword(String email) async {}

  @override
  Future<void> updateProfile({
    required String email,
    required Map<String, dynamic> metadata,
  }) async {
    if (!_isLoggedIn) {
      throw const AuthServiceException(
        AuthFailureType.validation,
        'Not signed in.',
      );
    }

    _email = email;
    _metadata = Map<String, dynamic>.from(metadata);
  }

  void dispose() {
    _authStateController.close();
  }
}

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

class _MockSupabaseClient extends Mock implements SupabaseClient {}

class _MockStreamHandler extends MockStreamHandler {
  @override
  void onListen(Object? arguments, MockStreamHandlerEventSink events) {}

  @override
  void onCancel(Object? arguments) {}
}
