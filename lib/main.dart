import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:clinic_go/core/themes/app_colors.dart';
import 'package:clinic_go/core/di/service_locator.dart';
import 'package:clinic_go/core/routing/app_router.dart';
import 'package:clinic_go/core/widgets/notification_lifecycle_wrapper.dart';
import 'package:clinic_go/features/home/presentation/views/main_screen.dart';
import 'package:clinic_go/features/medication/models/notification_payload.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://pizwimuaqaafcgfibkdy.supabase.co',
    anonKey: 'sb_secret_keDm_RYq9eICBxw1Pvty8g_5Wf3E7I5',
  );

  final navigatorKey = GlobalKey<NavigatorState>();
  final initialPayload = await setupServiceLocator(navigatorKey);

  runApp(
    ClinicGO(
      navigatorKey: navigatorKey,
      initialNotificationPayload: initialPayload,
    ),
  );
}

class ClinicGO extends StatefulWidget {
  const ClinicGO({
    super.key,
    this.navigatorKey,
    this.initialNotificationPayload,
  });

  final GlobalKey<NavigatorState>? navigatorKey;
  final NotificationPayload? initialNotificationPayload;

  @override
  State<ClinicGO> createState() => _ClinicGOState();
}

class _ClinicGOState extends State<ClinicGO> {
  bool _handledInitialNotification = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openInitialNotificationRoute();
    });
  }

  @override
  Widget build(BuildContext context) {
    return NotificationLifecycleWrapper(
      child: MaterialApp(
        title: 'ClinicGO',
        debugShowCheckedModeBanner: false,
        navigatorKey: widget.navigatorKey,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primaryColor),
        ),
        onGenerateRoute: AppRouter.onGenerateRoute,
        home: const MainScreen(),
      ),
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
