import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:clinic_go/features/auth/domain/auth_service.dart';
import 'package:clinic_go/features/auth/data/supabase_auth_service.dart';
import 'package:clinic_go/features/medication/data/supabase_dose_log_repository.dart';
import 'package:clinic_go/features/medication/data/dose_log_repository.dart';
import 'package:clinic_go/features/medication/data/medication_repository.dart';
import 'package:clinic_go/features/medication/data/supabase_medication_repository.dart';
import 'package:clinic_go/features/calendar/data/calendar_repository.dart';
import 'package:clinic_go/features/calendar/data/supabase_calendar_repository.dart';
import 'package:clinic_go/features/medication/services/missed_dose_notification_controller.dart';
import 'package:clinic_go/features/medication/services/local_notification_gateway.dart';
import 'package:clinic_go/features/medication/services/flutter_local_notification_gateway.dart';
import 'package:clinic_go/features/medication/services/pending_notification_store.dart';
import 'package:clinic_go/features/medication/services/dose_scheduling_service.dart';
import 'package:clinic_go/features/medication/models/notification_payload.dart';

final getIt = GetIt.instance;

Future<NotificationPayload?> setupServiceLocator(
  GlobalKey<NavigatorState> navigatorKey,
) async {
  // Supabase Client
  getIt.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);

  // Auth Service
  getIt.registerLazySingleton<AuthService>(() => SupabaseAuthService());

  // Dose Log Repository
  getIt.registerLazySingleton<DoseLogRepository>(
    () => SupabaseDoseLogRepository(getIt<SupabaseClient>()),
  );

  // Medication Repository
  getIt.registerLazySingleton<MedicationRepository>(
    () => SupabaseMedicationRepository(getIt<SupabaseClient>()),
  );

  // Pending Notification Store
  getIt.registerLazySingleton<PendingNotificationStore>(
    () => const PendingNotificationStore(),
  );

  // Dose Scheduling Service
  getIt.registerLazySingleton<DoseSchedulingService>(
    () => const DoseSchedulingService(),
  );

  // Calendar repository (reads dose_logs for calendar view)
  getIt.registerLazySingleton<CalendarRepository>(
    () => SupabaseCalendarRepository(getIt<SupabaseClient>()),
  );

  // Notification Gateway Bootstrap
  NotificationPayload? initialPayload;
  LocalNotificationGateway gateway;
  try {
    final flutterGateway = await FlutterLocalNotificationGateway.initialize(
      onPayloadSelected: (payload) {
        final navigator = navigatorKey.currentState;
        if (navigator == null) {
          return;
        }
        navigator.pushNamed(payload.route);
      },
    );
    gateway = flutterGateway;
    initialPayload = flutterGateway.initialPayload;
  } on MissingPluginException {
    gateway = const NoopLocalNotificationGateway();
  } catch (_) {
    gateway = const NoopLocalNotificationGateway();
  }

  getIt.registerSingleton<LocalNotificationGateway>(gateway);

  // Missed Dose Notification Controller
  getIt.registerSingleton<MissedDoseNotificationController>(
    MissedDoseNotificationController(
      notificationGateway: getIt<LocalNotificationGateway>(),
      doseLogRepository: getIt<DoseLogRepository>(),
      pendingNotificationStore: getIt<PendingNotificationStore>(),
    ),
  );

  return initialPayload;
}
