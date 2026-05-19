import 'dart:async';

import 'package:flutter/material.dart';
import 'package:clinic_go/features/auth/domain/auth_service.dart';
import 'package:clinic_go/features/medication/services/missed_dose_notification_controller.dart';
import 'package:clinic_go/features/medication/services/local_notification_gateway.dart';
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
  late final LocalNotificationGateway _notificationGateway;
  StreamSubscription<bool>? _authSubscription;
  bool _showPermissionWarning = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _notificationController = getIt<MissedDoseNotificationController>();
    _notificationGateway = getIt<LocalNotificationGateway>();
    _notificationController.syncPendingMissedNotifications();
    _initializeNotifications();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeNotifications() async {
    final granted = await _notificationGateway.requestPermissions();
    setState(() {
      _showPermissionWarning = !granted;
    });

    await _notificationController.refreshScheduledMedicationReminders();

    try {
      final authService = getIt<AuthService>();
      _authSubscription = authService.authStateChanges.listen((loggedIn) {
        if (loggedIn) {
          _notificationController.refreshScheduledMedicationReminders();
        }
      });
    } catch (_) {
      // ignore if authService isn't available through getIt; not fatal.
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _notificationController.syncPendingMissedNotifications();
      _notificationController.refreshScheduledMedicationReminders();
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = widget.child;
    if (!_showPermissionWarning) {
      return content;
    }

    return Column(
      children: [
        MaterialBanner(
          content: const Text(
            'Medication reminders are disabled. Enable notifications in your device settings to receive alerts.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _showPermissionWarning = false;
                });
              },
              child: const Text('DISMISS'),
            ),
          ],
        ),
        Expanded(child: content),
      ],
    );
  }
}
