import 'package:flutter/material.dart';
import 'package:clinic_go/features/medication/services/missed_dose_notification_controller.dart';
import 'package:clinic_go/core/di/service_locator.dart';

class NotificationLifecycleWrapper extends StatefulWidget {
  const NotificationLifecycleWrapper({super.key, required this.child});

  final Widget child;

  @override
  State<NotificationLifecycleWrapper> createState() =>
      _NotificationLifecycleWrapperState();
}

class _NotificationLifecycleWrapperState
    extends State<NotificationLifecycleWrapper>
    with WidgetsBindingObserver {
  late final MissedDoseNotificationController _notificationController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _notificationController = getIt<MissedDoseNotificationController>();
    _notificationController.syncPendingMissedNotifications();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _notificationController.syncPendingMissedNotifications();
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
