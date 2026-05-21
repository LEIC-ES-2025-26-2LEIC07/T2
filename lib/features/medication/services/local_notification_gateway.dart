class NotificationRequest {
  const NotificationRequest({
    required this.id,
    required this.title,
    required this.body,
    required this.scheduledTime,
    required this.payload,
  });

  final int id;
  final String title;
  final String body;
  final DateTime scheduledTime;
  final String payload;
}

abstract class LocalNotificationGateway {
  Future<void> schedule(NotificationRequest request);

  Future<void> cancel(int notificationId);

  Future<bool> requestPermissions();

  Future<bool> hasPermissions();
}

class NoopLocalNotificationGateway implements LocalNotificationGateway {
  const NoopLocalNotificationGateway();

  @override
  Future<void> cancel(int notificationId) async {}

  @override
  Future<void> schedule(NotificationRequest request) async {}

  @override
  Future<bool> requestPermissions() async => true;

  @override
  Future<bool> hasPermissions() async => true;
}
