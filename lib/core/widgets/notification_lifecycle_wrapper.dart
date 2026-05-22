import 'dart:async';

import 'package:flutter/material.dart';
import 'package:clinic_go/features/auth/domain/auth_service.dart';
import 'package:clinic_go/features/emergency_alerts/presentation/view_models/emergency_alert_controller.dart';
import 'package:clinic_go/features/emergency_alerts/presentation/widgets/emergency_alert_banner.dart';
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
  EmergencyAlertController? _emergencyAlertController;
  StreamSubscription<bool>? _authSubscription;
  bool _showPermissionWarning = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _notificationController = getIt<MissedDoseNotificationController>();
    _notificationGateway = getIt<LocalNotificationGateway>();
    if (getIt.isRegistered<EmergencyAlertController>()) {
      _emergencyAlertController = getIt<EmergencyAlertController>()
        ..addListener(_onEmergencyAlertChanged)
        ..initialize();
    }
    _notificationController.syncPendingMissedNotifications();
    _initializeNotifications();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authSubscription?.cancel();
    _emergencyAlertController?.removeListener(_onEmergencyAlertChanged);
    super.dispose();
  }

  Future<void> _initializeNotifications() async {
    final granted = await _notificationGateway.requestPermissions();
    if (!mounted) return;
    setState(() {
      _showPermissionWarning = !granted;
    });

    await _notificationController.refreshScheduledMedicationReminders();

    try {
      final authService = getIt<AuthService>();
      _authSubscription = authService.authStateChanges.listen((_) {
        final signedIn = authService.isLoggedIn;
        if (signedIn) {
          _notificationController.refreshScheduledMedicationReminders();
          _emergencyAlertController?.handleSignedIn();
        } else {
          _emergencyAlertController?.handleSignedOut();
        }
      });
    } catch (error) {
      debugPrint(
        'NotificationLifecycleWrapper: auth listener setup failed: $error',
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _notificationController.syncPendingMissedNotifications();
      _notificationController.refreshScheduledMedicationReminders();
      _notificationGateway.hasPermissions().then((granted) {
        if (mounted) {
          setState(() => _showPermissionWarning = !granted);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = _buildNotificationPermissionContent(widget.child);
    final emergencyAlert = _emergencyAlertController?.activeAlert;
    if (emergencyAlert == null) {
      return content;
    }

    return Stack(
      children: [
        content,
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          child: EmergencyAlertBanner(
            alert: emergencyAlert,
            onOpen: () =>
                _emergencyAlertController?.openAlert(emergencyAlert.id),
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationPermissionContent(Widget content) {
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

  void _onEmergencyAlertChanged() {
    if (mounted) setState(() {});
  }
}
