import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/notification_payload.dart';
import 'local_notification_gateway.dart';

class FlutterLocalNotificationGateway implements LocalNotificationGateway {
  FlutterLocalNotificationGateway._(
    this._plugin, {
    required this.initialPayload,
  });

  final FlutterLocalNotificationsPlugin _plugin;
  final NotificationPayload? initialPayload;

  static bool _timeZonesInitialized = false;

  static Future<FlutterLocalNotificationGateway> initialize({
    required void Function(NotificationPayload payload) onPayloadSelected,
  }) async {
    await _configureTimeZone();

    final plugin = FlutterLocalNotificationsPlugin();
    await plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
        macOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null || payload.isEmpty) {
          return;
        }

        onPayloadSelected(NotificationPayload.decode(payload));
      },
    );

    final androidPlugin = plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.requestNotificationsPermission();
    await androidPlugin?.requestExactAlarmsPermission();
    await plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    await plugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    final launchDetails = await plugin.getNotificationAppLaunchDetails();
    final launchPayload = launchDetails?.didNotificationLaunchApp == true
        ? launchDetails?.notificationResponse?.payload
        : null;

    return FlutterLocalNotificationGateway._(
      plugin,
      initialPayload: launchPayload == null || launchPayload.isEmpty
          ? null
          : NotificationPayload.decode(launchPayload),
    );
  }

  @override
  Future<void> cancel(int notificationId) => _plugin.cancel(id: notificationId);

  @override
  Future<void> schedule(NotificationRequest request) async {
    final scheduledDate = tz.TZDateTime.from(request.scheduledTime, tz.local);
    final isMissedDoseAlert = request.payload.contains('"status":"overdue"');

    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final canExact =
        await androidImpl?.canScheduleExactNotifications() ?? false;
    final scheduleMode = canExact
        ? AndroidScheduleMode.exact
        : AndroidScheduleMode.inexactAllowWhileIdle;

    return _plugin.zonedSchedule(
      id: request.id,
      title: request.title,
      body: request.body,
      scheduledDate: scheduledDate,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          isMissedDoseAlert
              ? 'missed_medication_alerts'
              : 'medication_reminders',
          isMissedDoseAlert
              ? 'Missed medication alerts'
              : 'Medication reminders',
          channelDescription: isMissedDoseAlert
              ? 'Urgent alerts for overdue scheduled doses'
              : 'Scheduled reminders for upcoming medication doses',
          importance: Importance.max,
          priority: Priority.high,
          category: AndroidNotificationCategory.reminder,
        ),
        iOS: DarwinNotificationDetails(
          interruptionLevel: isMissedDoseAlert
              ? InterruptionLevel.timeSensitive
              : InterruptionLevel.active,
        ),
        macOS: DarwinNotificationDetails(
          interruptionLevel: isMissedDoseAlert
              ? InterruptionLevel.timeSensitive
              : InterruptionLevel.active,
        ),
      ),
      payload: request.payload,
      androidScheduleMode: scheduleMode,
    );
  }

  static Future<void> _configureTimeZone() async {
    if (!_timeZonesInitialized) {
      tz.initializeTimeZones();
      _timeZonesInitialized = true;
    }

    try {
      final timezoneName =
          (await FlutterTimezone.getLocalTimezone()).identifier;
      tz.setLocalLocation(tz.getLocation(timezoneName));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }
  }
}
