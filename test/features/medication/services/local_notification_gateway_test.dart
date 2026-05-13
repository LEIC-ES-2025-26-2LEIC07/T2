import 'package:flutter_test/flutter_test.dart';
import 'package:clinic_go/features/medication/services/local_notification_gateway.dart';

void main() {
  group('NoopLocalNotificationGateway', () {
    late NoopLocalNotificationGateway gateway;

    setUp(() {
      gateway = const NoopLocalNotificationGateway();
    });

    test('schedule completes without error', () async {
      await expectLater(
        gateway.schedule(
          NotificationRequest(
            id: 1,
            title: 'Test',
            body: 'Body',
            scheduledTime: DateTime(2026, 1, 1, 8),
            payload: '{}',
          ),
        ),
        completes,
      );
    });

    test('cancel completes without error', () async {
      await expectLater(gateway.cancel(42), completes);
    });

    test('cancel with any id completes', () async {
      await expectLater(gateway.cancel(0), completes);
      await expectLater(gateway.cancel(999), completes);
    });
  });

  group('NotificationRequest', () {
    test('stores all fields correctly', () {
      final scheduledTime = DateTime(2026, 4, 16, 8);
      final request = NotificationRequest(
        id: 7,
        title: 'Medication Time',
        body: 'Take your pill',
        scheduledTime: scheduledTime,
        payload: '{"doseId":"abc"}',
      );

      expect(request.id, 7);
      expect(request.title, 'Medication Time');
      expect(request.body, 'Take your pill');
      expect(request.scheduledTime, scheduledTime);
      expect(request.payload, '{"doseId":"abc"}');
    });
  });
}
