import 'package:flutter/material.dart';
import 'package:clinic_go/core/di/service_locator.dart';
import 'package:clinic_go/features/auth/presentation/views/login_screen.dart';
import 'package:clinic_go/features/auth/presentation/views/register_screen.dart';
import 'package:clinic_go/features/home/presentation/views/main_screen.dart';
import 'package:clinic_go/features/medication/models/scheduled_dose.dart';
import 'package:clinic_go/features/medication/presentation/views/dose_logging_screen.dart';
import 'package:clinic_go/features/medication/services/missed_dose_notification_controller.dart';

/// Centralized route factory for the ClinicGO app.
///
/// As the app grows, add new named-route cases here so that navigation
/// logic stays out of individual widgets and out of main.dart.
class AppRouter {
  const AppRouter._();

  static const String home = '/home';
  static const String login = '/login';
  static const String register = '/register';

  /// Called by [MaterialApp.onGenerateRoute].
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final routeName = settings.name;

    if (routeName == home) {
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => const MainScreen(),
      );
    }

    if (routeName == login) {
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => const LoginScreen(),
      );
    }

    if (routeName == register) {
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => const RegisterScreen(),
      );
    }

    if (routeName == null || !routeName.startsWith('/log-dose/')) return null;

    final uri = Uri.parse(routeName);
    final doseId = uri.pathSegments.length > 1 ? uri.pathSegments[1] : null;
    if (doseId == null) {
      return null;
    }

    final scheduledTime = DateTime.tryParse(
      uri.queryParameters['scheduledTime'] ?? '',
    );
    final medicationId = uri.queryParameters['medicationId'];
    final medicationName = uri.queryParameters['medicationName'];
    final dosage = uri.queryParameters['dosage'];

    if (scheduledTime == null ||
        medicationId == null ||
        medicationName == null ||
        dosage == null) {
      return null;
    }

    final dose = ScheduledDose(
      id: doseId,
      medicationId: medicationId,
      medicationName: medicationName,
      dosage: dosage,
      scheduledTime: scheduledTime,
    );

    final controller = getIt<MissedDoseNotificationController>();

    return MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => DoseLoggingScreen(
        dose: dose,
        controller: controller,
        isOverdue: uri.queryParameters['status'] == 'overdue',
      ),
    );
  }
}
