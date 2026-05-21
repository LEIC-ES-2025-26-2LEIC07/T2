import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:clinic_go/features/auth/domain/auth_service.dart';
import 'package:clinic_go/features/auth/presentation/views/sign_up_sheet.dart';
import 'package:clinic_go/features/medication/services/local_notification_gateway.dart';
import 'package:clinic_go/features/medication/services/pending_notification_store.dart';
import 'package:clinic_go/features/medication/data/dose_log_repository.dart';
import 'package:clinic_go/features/medication/models/scheduled_dose.dart';
import 'package:clinic_go/features/medication/services/missed_dose_notification_controller.dart';
import '../../../../helpers/mocks.dart';

class _MemoryNotificationGateway implements LocalNotificationGateway {
  @override
  Future<void> cancel(int notificationId) async {}

  @override
  Future<void> schedule(NotificationRequest request) async {}

  @override
  Future<bool> hasPermissions() async => true;

  @override
  Future<bool> requestPermissions() async => true;
}

class _NoOpDoseLogRepository implements DoseLogRepository {
  @override
  Future<bool> hasDoseLog(String doseId) async => false;

  @override
  Future<void> insertDoseLog({
    required ScheduledDose dose,
    required DoseLogStatus status,
    required DateTime loggedAt,
  }) async {}
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Registers a minimal DI environment for widget tests.
Future<void> _setupDI({AuthService? authService}) async {
  await GetIt.I.reset();
  SharedPreferences.setMockInitialValues({});

  GetIt.I.registerSingleton<AuthService>(authService ?? AlwaysSuccessAuth());
  GetIt.I.registerSingleton<MissedDoseNotificationController>(
    MissedDoseNotificationController(
      notificationGateway: _MemoryNotificationGateway(),
      doseLogRepository: _NoOpDoseLogRepository(),
      pendingNotificationStore: const PendingNotificationStore(),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  tearDown(() async => GetIt.I.reset());

  // ── Sign-up sheet widget tests ──────────────────────────────────────────────

  group('SignUpSheet', () {
    testWidgets('renders email, password, and confirm fields', (tester) async {
      await _setupDI();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) {
                return ElevatedButton(
                  onPressed: () => SignUpSheet.show(ctx),
                  child: const Text('Open'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Create account'), findsWidgets);
      expect(find.byType(TextField), findsNWidgets(3));
    });

    testWidgets('shows error message when fields are empty', (tester) async {
      await _setupDI();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) {
                return ElevatedButton(
                  onPressed: () => SignUpSheet.show(ctx),
                  child: const Text('Open'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Tap Create Account without filling anything
      await tester.tap(find.text('Create account').last);
      await tester.pumpAndSettle();

      expect(find.textContaining('Please fill in'), findsOneWidget);
    });

    testWidgets('shows error when passwords do not match', (tester) async {
      await _setupDI();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) {
                return ElevatedButton(
                  onPressed: () => SignUpSheet.show(ctx),
                  child: const Text('Open'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'a@b.com');
      await tester.enterText(fields.at(1), 'abc123');
      await tester.enterText(fields.at(2), 'different');

      await tester.tap(find.text('Create account').last);
      await tester.pumpAndSettle();

      expect(find.textContaining('match'), findsOneWidget);
    });

    testWidgets('closes sheet when "Already have an account" is tapped', (
      tester,
    ) async {
      await _setupDI();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) {
                return ElevatedButton(
                  onPressed: () => SignUpSheet.show(ctx),
                  child: const Text('Open'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Create account'), findsWidgets);

      await tester.tap(find.text('Already have an account'));
      await tester.pumpAndSettle();

      expect(find.text('Registar'), findsNothing);
      expect(find.text('Open'), findsOneWidget); // back on original screen
    });
  });
}
