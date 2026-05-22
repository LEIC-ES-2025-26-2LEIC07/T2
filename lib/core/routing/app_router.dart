import 'package:flutter/material.dart';
import 'package:clinic_go/core/di/service_locator.dart';
import 'package:clinic_go/features/auth/presentation/views/login_screen.dart';
import 'package:clinic_go/features/auth/presentation/views/register_screen.dart';
import 'package:clinic_go/features/emergency_alerts/presentation/views/emergency_alert_detail_screen.dart';
import 'package:clinic_go/features/home/presentation/views/main_screen.dart';
import 'package:clinic_go/features/medication/models/scheduled_dose.dart';
import 'package:clinic_go/features/medication/presentation/views/dose_logging_screen.dart';
import 'package:clinic_go/features/medication/services/missed_dose_notification_controller.dart';
import 'package:clinic_go/features/symptoms/presentation/views/log_symptom_screen.dart';
import 'package:clinic_go/features/symptoms/presentation/views/symptom_history_screen.dart';

/// Centralized route factory for the ClinicGO app.
///
/// As the app grows, add new named-route cases here so that navigation
/// logic stays out of individual widgets and out of main.dart.
class AppRouter {
  const AppRouter._();

  static const String home = '/home';
  static const String login = '/login';
  static const String register = '/register';
  static const String logSymptom = '/log-symptom';
  static const String symptomHistory = '/symptom-history';
  static const String emergencyAlertPrefix = '/emergency-alert';

  /// Called by [MaterialApp.onGenerateRoute].
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final routeName = settings.name;

    if (routeName == home) {
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => const MainScreen(),
      );
    }

    if (routeName == logSymptom) {
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => const LogSymptomScreen(),
      );
    }

    if (routeName == symptomHistory) {
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => const SymptomHistoryScreen(),
      );
    }

    if (routeName == login) {
      final successMessage = settings.arguments is String
          ? settings.arguments as String
          : null;

      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => LoginScreen(successMessage: successMessage),
      );
    }

    if (routeName == register) {
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => const RegisterScreen(),
      );
    }

    if (routeName != null && routeName.startsWith('$emergencyAlertPrefix/')) {
      final uri = Uri.parse(routeName);
      final rawId = uri.pathSegments.length > 1 ? uri.pathSegments[1] : null;
      final alertId = rawId != null ? Uri.decodeComponent(rawId) : null;
      if (alertId == null || alertId.isEmpty) return null;

      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => EmergencyAlertDetailScreen(alertId: alertId),
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

    return MaterialPageRoute<bool>(
      settings: settings,
      builder: (_) => DoseLoggingScreen(
        dose: dose,
        controller: controller,
        isOverdue: uri.queryParameters['status'] == 'overdue',
      ),
    );
  }
}
