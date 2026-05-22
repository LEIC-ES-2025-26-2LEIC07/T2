import 'dart:async';

class PushMessage {
  const PushMessage({required this.data, this.title, this.body});

  final Map<String, dynamic> data;
  final String? title;
  final String? body;
}

abstract class PushMessagingGateway {
  Stream<PushMessage> get foregroundMessages;

  Stream<PushMessage> get notificationTaps;

  PushMessage? get initialMessage;

  Future<bool> requestEmergencyPermissions();

  Future<String?> getToken();

  Stream<String> get tokenRefreshes;
}

class NoopPushMessagingGateway implements PushMessagingGateway {
  const NoopPushMessagingGateway();

  @override
  Stream<PushMessage> get foregroundMessages => const Stream.empty();

  @override
  Stream<PushMessage> get notificationTaps => const Stream.empty();

  @override
  PushMessage? get initialMessage => null;

  @override
  Future<String?> getToken() async => null;

  @override
  Future<bool> requestEmergencyPermissions() async => true;

  @override
  Stream<String> get tokenRefreshes => const Stream.empty();
}
