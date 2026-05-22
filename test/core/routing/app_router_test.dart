import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:clinic_go/core/routing/app_router.dart';
import 'package:clinic_go/features/auth/domain/auth_service.dart';
import 'package:clinic_go/features/medication/data/dose_log_repository.dart';
import 'package:clinic_go/features/medication/models/scheduled_dose.dart';
import 'package:clinic_go/features/medication/services/local_notification_gateway.dart';
import 'package:clinic_go/features/medication/services/missed_dose_notification_controller.dart';
import 'package:clinic_go/features/medication/services/pending_notification_store.dart';
import '../../helpers/mocks.dart';

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

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await GetIt.I.reset();
    GetIt.I.registerSingleton<AuthService>(AlwaysSuccessAuth());
    GetIt.I.registerSingleton<MissedDoseNotificationController>(
      MissedDoseNotificationController(
        notificationGateway: const NoopLocalNotificationGateway(),
        doseLogRepository: _NoOpDoseLogRepository(),
        pendingNotificationStore: const PendingNotificationStore(),
      ),
    );
  });

  tearDown(() async => GetIt.I.reset());

  group('AppRouter.onGenerateRoute', () {
    test('returns null for null route name', () {
      final route = AppRouter.onGenerateRoute(const RouteSettings(name: null));
      expect(route, isNull);
    });

    test('returns null for unknown route', () {
      final route = AppRouter.onGenerateRoute(
        const RouteSettings(name: '/unknown'),
      );
      expect(route, isNull);
    });

    test('returns MaterialPageRoute for /home', () {
      final route = AppRouter.onGenerateRoute(
        const RouteSettings(name: AppRouter.home),
      );
      expect(route, isA<MaterialPageRoute>());
    });

    test('returns MaterialPageRoute for /login', () {
      final route = AppRouter.onGenerateRoute(
        const RouteSettings(name: AppRouter.login),
      );
      expect(route, isA<MaterialPageRoute>());
    });

    test('returns MaterialPageRoute for /register', () {
      final route = AppRouter.onGenerateRoute(
        const RouteSettings(name: AppRouter.register),
      );
      expect(route, isA<MaterialPageRoute>());
    });

    test('returns null for /log-dose/ with no doseId', () {
      final route = AppRouter.onGenerateRoute(
        const RouteSettings(name: '/log-dose/'),
      );
      expect(route, isNull);
    });

    test('returns null for /log-dose/id missing required params', () {
      final route = AppRouter.onGenerateRoute(
        const RouteSettings(name: '/log-dose/dose-1?medicationId=med-1'),
      );
      expect(route, isNull);
    });

    test('returns null for /log-dose/id with invalid scheduledTime', () {
      const routeName =
          '/log-dose/dose-1?medicationId=med-1&medicationName=Aspirin&dosage=100mg&scheduledTime=notadate';
      final route = AppRouter.onGenerateRoute(RouteSettings(name: routeName));
      expect(route, isNull);
    });

    test('returns MaterialPageRoute for valid /log-dose/ with all params', () {
      const routeName =
          '/log-dose/dose-1'
          '?medicationId=med-1'
          '&medicationName=Aspirin'
          '&dosage=100mg'
          '&scheduledTime=2026-01-01T08%3A00%3A00.000'
          '&status=overdue';
      final route = AppRouter.onGenerateRoute(RouteSettings(name: routeName));
      expect(route, isA<MaterialPageRoute>());
    });

    test('returns MaterialPageRoute for emergency alert route', () {
      final route = AppRouter.onGenerateRoute(
        const RouteSettings(name: '/emergency-alert/alert-1'),
      );
      expect(route, isA<MaterialPageRoute>());
    });

    test('route constants have correct values', () {
      expect(AppRouter.home, '/home');
      expect(AppRouter.login, '/login');
      expect(AppRouter.register, '/register');
    });
  });
}
