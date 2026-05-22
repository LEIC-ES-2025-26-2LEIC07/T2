import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/emergency_alert_repository.dart';
import '../../models/emergency_alert.dart';
import '../../services/emergency_alert_store.dart';
import '../../services/push_messaging_gateway.dart';

class EmergencyAlertController extends ChangeNotifier {
  EmergencyAlertController({
    required EmergencyAlertRepository repository,
    required EmergencyAlertStore store,
    required PushMessagingGateway pushGateway,
    void Function(String route)? onOpenRoute,
  }) : _repository = repository,
       _store = store,
       _pushGateway = pushGateway,
       _onOpenRoute = onOpenRoute;

  final EmergencyAlertRepository _repository;
  final EmergencyAlertStore _store;
  final PushMessagingGateway _pushGateway;
  final void Function(String route)? _onOpenRoute;
  final List<EmergencyAlert> _alerts = [];

  StreamSubscription<EmergencyAlert>? _realtimeSubscription;
  StreamSubscription<PushMessage>? _foregroundSubscription;
  StreamSubscription<PushMessage>? _tapSubscription;
  StreamSubscription<String>? _tokenRefreshSubscription;
  String? _currentToken;
  bool _initialized = false;

  List<EmergencyAlert> get alerts => List.unmodifiable(_alerts);

  EmergencyAlert? get activeAlert => _alerts.isEmpty ? null : _alerts.first;

  EmergencyAlert? alertById(String id) {
    for (final alert in _alerts) {
      if (alert.id == id) return alert;
    }
    return null;
  }

  Future<void> loadAlert(String id) async {
    if (alertById(id) != null) return;
    try {
      final alert = await _repository.fetchAlert(id);
      if (alert != null && !alert.isAcknowledged) {
        await _upsertAlert(alert);
      }
    } catch (error) {
      debugPrint('EmergencyAlertController.loadAlert failed: $error');
    }
  }

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    await _loadCachedAlerts();
    await _syncRemoteAlerts();
    _subscribeToRealtimeAlerts();
    await _registerPushToken();

    _foregroundSubscription = _pushGateway.foregroundMessages.listen(
      _handlePushMessage,
    );
    _tapSubscription = _pushGateway.notificationTaps.listen(
      (message) => _handlePushMessage(message, openDetails: true),
    );
    _tokenRefreshSubscription = _pushGateway.tokenRefreshes.listen(_syncToken);

    final initial = _pushGateway.initialMessage;
    if (initial != null) {
      unawaited(_handlePushMessage(initial, openDetails: true));
    }
  }

  Future<void> acknowledge(String id) async {
    try {
      await _repository.acknowledgeAlert(id);
    } catch (error) {
      debugPrint('EmergencyAlertController.acknowledge failed: $error');
    }

    _alerts.removeWhere((alert) => alert.id == id);
    await _store.remove(id);
    notifyListeners();
  }

  Future<void> handleSignedIn() async {
    await _registerPushToken();
    await _syncRemoteAlerts();
  }

  Future<void> handleSignedOut() async {
    final token = _currentToken;
    if (token != null) {
      try {
        await _repository.removePushToken(token);
      } catch (error) {
        debugPrint('EmergencyAlertController.remove token failed: $error');
      }
    }
    await _store.clear();
    _alerts.clear();
    notifyListeners();
  }

  void openAlert(String id) => _onOpenRoute?.call(buildEmergencyAlertRoute(id));

  Future<void> _loadCachedAlerts() async {
    try {
      _replaceAlerts(await _store.loadUnacknowledged());
    } catch (error) {
      debugPrint('EmergencyAlertController cache load failed: $error');
    }
  }

  Future<void> _syncRemoteAlerts() async {
    try {
      final remoteAlerts = await _repository.fetchUnacknowledgedAlerts();
      if (remoteAlerts.isEmpty) return;
      _replaceAlerts([...remoteAlerts, ..._alerts]);
      await _store.replaceAll(_alerts);
    } catch (error) {
      debugPrint('EmergencyAlertController remote sync failed: $error');
    }
  }

  void _subscribeToRealtimeAlerts() {
    _realtimeSubscription = _repository.watchInsertedAlerts().listen(
      (alert) async {
        await _upsertAlert(alert);
      },
      onError: (error) {
        debugPrint('EmergencyAlertController realtime failed: $error');
      },
    );
  }

  Future<void> _registerPushToken() async {
    try {
      final granted = await _pushGateway.requestEmergencyPermissions();
      if (!granted) return;

      final token = await _pushGateway.getToken();
      if (token != null) {
        await _syncToken(token);
      }
    } catch (error) {
      debugPrint('EmergencyAlertController token registration failed: $error');
    }
  }

  Future<void> _syncToken(String token) async {
    _currentToken = token;
    try {
      await _repository.syncPushToken(token, _platformName());
    } catch (error) {
      debugPrint('EmergencyAlertController token sync failed: $error');
    }
  }

  Future<void> _handlePushMessage(
    PushMessage message, {
    bool openDetails = false,
  }) async {
    if (message.data['type'] != 'emergency') return;

    final alertId = message.data['alert_id']?.toString();
    if (alertId == null || alertId.isEmpty) return;

    var alert = alertById(alertId);
    if (alert == null) {
      try {
        alert = await _repository.fetchAlert(alertId);
      } catch (error) {
        debugPrint(
          'EmergencyAlertController fetch pushed alert failed: $error',
        );
      }
    }

    alert ??= EmergencyAlert(
      id: alertId,
      title: message.title ?? 'Emergency alert',
      message: message.body ?? 'A critical health alert needs your attention.',
      createdAt: DateTime.now(),
    );

    await _upsertAlert(alert);
    if (openDetails) openAlert(alert.id);
  }

  Future<void> _upsertAlert(EmergencyAlert alert) async {
    _alerts.removeWhere((item) => item.id == alert.id);
    _alerts.insert(0, alert);
    _sortAlerts();
    await _store.upsert(alert);
    notifyListeners();
  }

  void _replaceAlerts(List<EmergencyAlert> alerts) {
    final byId = <String, EmergencyAlert>{};
    for (final alert in alerts.where((alert) => !alert.isAcknowledged)) {
      byId[alert.id] = alert;
    }
    _alerts
      ..clear()
      ..addAll(byId.values);
    _sortAlerts();
    notifyListeners();
  }

  void _sortAlerts() {
    _alerts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  String _platformName() {
    if (kIsWeb) return 'web';
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'android',
      TargetPlatform.iOS => 'ios',
      TargetPlatform.macOS => 'macos',
      TargetPlatform.linux => 'linux',
      TargetPlatform.windows => 'windows',
      TargetPlatform.fuchsia => 'fuchsia',
    };
  }

  @override
  void dispose() {
    _realtimeSubscription?.cancel();
    _foregroundSubscription?.cancel();
    _tapSubscription?.cancel();
    _tokenRefreshSubscription?.cancel();
    super.dispose();
  }
}

String buildEmergencyAlertRoute(String alertId) =>
    '/emergency-alert/${Uri.encodeComponent(alertId)}';
