import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/emergency_alert.dart';

class EmergencyAlertStore {
  const EmergencyAlertStore();

  static const _storageKey = 'unacknowledged_emergency_alerts';

  Future<List<EmergencyAlert>> loadUnacknowledged() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs
        .getStringList(_storageKey)
        .orEmpty()
        .map(
          (value) => EmergencyAlert.fromJson(
            jsonDecode(value) as Map<String, dynamic>,
          ),
        )
        .where((alert) => !alert.isAcknowledged)
        .toList();
  }

  Future<void> upsert(EmergencyAlert alert) async {
    final alerts = await loadUnacknowledged();
    final next = [alert, ...alerts.where((item) => item.id != alert.id)];
    await _save(next);
  }

  Future<void> replaceAll(List<EmergencyAlert> alerts) async {
    await _save(alerts.where((alert) => !alert.isAcknowledged).toList());
  }

  Future<void> remove(String id) async {
    final alerts = await loadUnacknowledged();
    await _save(alerts.where((alert) => alert.id != id).toList());
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  Future<void> _save(List<EmergencyAlert> alerts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _storageKey,
      alerts.map((alert) => jsonEncode(alert.toJson())).toList(),
    );
  }
}

extension on List<String>? {
  List<String> orEmpty() => this ?? const [];
}
