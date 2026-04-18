import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:clinic_go/core/themes/app_colors.dart';
import 'package:clinic_go/features/home/presentation/views/main_screen.dart';
import 'package:clinic_go/features/medication/data/supabase_dose_log_repository.dart';
import 'package:clinic_go/features/medication/models/scheduled_dose.dart';
import 'package:clinic_go/features/medication/models/notification_payload.dart';
import 'package:clinic_go/features/medication/services/flutter_local_notification_gateway.dart';
import 'package:clinic_go/features/medication/services/local_notification_gateway.dart';
import 'package:clinic_go/features/medication/services/missed_dose_notification_controller.dart';
import 'package:clinic_go/features/medication/services/pending_notification_store.dart';
import 'package:clinic_go/features/medication/presentation/views/dose_logging_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://pizwimuaqaafcgfibkdy.supabase.co',
    anonKey: 'sb_secret_keDm_RYq9eICBxw1Pvty8g_5Wf3E7I5',
  );

  final navigatorKey = GlobalKey<NavigatorState>();
  final notificationBootstrap = await _buildNotificationBootstrap(navigatorKey);

  runApp(
    ClinicGO(
      navigatorKey: navigatorKey,
      notificationController: MissedDoseNotificationController(
        notificationGateway: notificationBootstrap.gateway,
        doseLogRepository: SupabaseDoseLogRepository(Supabase.instance.client),
        pendingNotificationStore: const PendingNotificationStore(),
      ),
      initialNotificationPayload: notificationBootstrap.initialPayload,
    ),
  );
}

class ClinicGO extends StatefulWidget {
  const ClinicGO({
    super.key,
    this.notificationController,
    this.initialNotificationPayload,
    this.navigatorKey,
  });

  final MissedDoseNotificationController? notificationController;
  final NotificationPayload? initialNotificationPayload;
  final GlobalKey<NavigatorState>? navigatorKey;

  @override
  State<ClinicGO> createState() => _ClinicGOState();
}

class _ClinicGOState extends State<ClinicGO> with WidgetsBindingObserver {
  bool _handledInitialNotification = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.notificationController?.syncPendingMissedNotifications();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openInitialNotificationRoute();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      widget.notificationController?.syncPendingMissedNotifications();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ClinicGO',
      debugShowCheckedModeBanner: false,
      navigatorKey: widget.navigatorKey,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primaryColor),
      ),
      onGenerateRoute: (settings) =>
          _buildRoute(settings, widget.notificationController),
      home: MainScreen(notificationController: widget.notificationController),
    );
  }

  void _openInitialNotificationRoute() {
    if (_handledInitialNotification) {
      return;
    }

    final payload = widget.initialNotificationPayload;
    final navigator = widget.navigatorKey?.currentState;
    if (payload == null || navigator == null) {
      return;
    }

    _handledInitialNotification = true;
    navigator.pushNamed(payload.route);
  }
}

Route<dynamic>? _buildRoute(
  RouteSettings settings,
  MissedDoseNotificationController? controller,
) {
  final routeName = settings.name;
  if (routeName == null || !routeName.startsWith('/log-dose/')) {
    return null;
  }

  final uri = Uri.parse(routeName);
  final doseId = uri.pathSegments.length > 1 ? uri.pathSegments[1] : null;
  if (doseId == null || controller == null) {
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

  return MaterialPageRoute<void>(
    settings: settings,
    builder: (_) => DoseLoggingScreen(
      dose: dose,
      controller: controller,
      isOverdue: uri.queryParameters['status'] == 'overdue',
    ),
  );
}

Future<_NotificationBootstrap> _buildNotificationBootstrap(
  GlobalKey<NavigatorState> navigatorKey,
) async {
  try {
    final gateway = await FlutterLocalNotificationGateway.initialize(
      onPayloadSelected: (payload) {
        final navigator = navigatorKey.currentState;
        if (navigator == null) {
          return;
        }

        navigator.pushNamed(payload.route);
      },
    );

    return _NotificationBootstrap(
      gateway: gateway,
      initialPayload: gateway.initialPayload,
    );
  } on MissingPluginException {
    return const _NotificationBootstrap(
      gateway: NoopLocalNotificationGateway(),
    );
  } catch (_) {
    return const _NotificationBootstrap(
      gateway: NoopLocalNotificationGateway(),
    );
  }
}

class _NotificationBootstrap {
  const _NotificationBootstrap({required this.gateway, this.initialPayload});

  final LocalNotificationGateway gateway;
  final NotificationPayload? initialPayload;
}
