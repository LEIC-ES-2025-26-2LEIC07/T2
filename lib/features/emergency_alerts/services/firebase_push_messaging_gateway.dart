import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'push_messaging_gateway.dart';

@pragma('vm:entry-point')
Future<void> clinicGoFirebaseMessagingBackgroundHandler(
  RemoteMessage message,
) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
}

class FirebasePushMessagingGateway implements PushMessagingGateway {
  FirebasePushMessagingGateway._(this._messaging, this._initialMessage);

  final FirebaseMessaging _messaging;
  final PushMessage? _initialMessage;

  static Future<FirebasePushMessagingGateway> initialize() async {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(
      clinicGoFirebaseMessagingBackgroundHandler,
    );

    final messaging = FirebaseMessaging.instance;
    final initial = await messaging.getInitialMessage();

    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    return FirebasePushMessagingGateway._(
      messaging,
      initial == null ? null : _fromRemoteMessage(initial),
    );
  }

  @override
  Stream<PushMessage> get foregroundMessages =>
      FirebaseMessaging.onMessage.map(_fromRemoteMessage);

  @override
  Stream<PushMessage> get notificationTaps =>
      FirebaseMessaging.onMessageOpenedApp.map(_fromRemoteMessage);

  @override
  PushMessage? get initialMessage => _initialMessage;

  @override
  Future<String?> getToken() => _messaging.getToken();

  @override
  Future<bool> requestEmergencyPermissions() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      criticalAlert: true,
      provisional: false,
    );
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  @override
  Stream<String> get tokenRefreshes => _messaging.onTokenRefresh;

  static PushMessage _fromRemoteMessage(RemoteMessage message) => PushMessage(
    data: message.data,
    title: message.notification?.title,
    body: message.notification?.body,
  );
}
