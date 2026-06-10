/// Manual smoke test — run on an Android emulator to verify that
/// local notifications are actually delivered by the OS.
///
/// How to run:
///   flutter test integration_test/notification_delivery_test.dart \
///     -d EMULATOR_ID
///
/// What to do:
///   1. Run the test.
///   2. When the emulator's screen turns on, swipe it to the background
///      (Home button) within the first few seconds.
///   3. After ~10 s you should see the notification in the status bar.
///
/// If the notification never arrives, check:
///   - Emulator → Settings → Apps → ClinicGO → Notifications → All allowed
///   - Emulator → Settings → Apps → ClinicGO → Alarms & Reminders → Allowed
///     (required for AndroidScheduleMode.exact on API 31+)
library;

import 'dart:io' show Platform;

import 'package:clinic_go/features/medication/services/flutter_local_notification_gateway.dart';
import 'package:clinic_go/features/medication/services/local_notification_gateway.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'schedules a real notification that arrives ~10 s from now',
    skip: !Platform.isAndroid,
    (tester) async {
      final gateway = await FlutterLocalNotificationGateway.initialize(
        onPayloadSelected: (_) {},
      );

      await gateway.schedule(
        NotificationRequest(
          id: 9999,
          title: 'TEST: Medication Reminder',
          body: 'Se vês isto, as notificações funcionam!',
          scheduledTime: DateTime.now().add(const Duration(seconds: 3)),
          payload: '{"status":"scheduled","doseId":"test-delivery"}',
        ),
      );

      // Keep the test alive so the process doesn't die before the alarm fires.
      // The notification should appear as a heads-up banner at ~3 s.
      await tester.pump(const Duration(seconds: 10));
    },
  );
}
