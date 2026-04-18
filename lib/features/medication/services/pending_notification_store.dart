import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/pending_missed_dose_notification.dart';

class PendingNotificationStore {
  const PendingNotificationStore();

  static const _storageKey = 'pending_missed_dose_notifications';

  Future<List<PendingMissedDoseNotification>> loadPending() async {
    final preferences = await SharedPreferences.getInstance();
    final rawItems = preferences.getStringList(_storageKey) ?? const [];

    return rawItems
        .map(
          (item) => PendingMissedDoseNotification.fromJson(
            jsonDecode(item) as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<void> upsert(PendingMissedDoseNotification notification) async {
    final notifications = await loadPending();
    final nextNotifications = [
      ...notifications.where((item) => item.dose.id != notification.dose.id),
      notification,
    ];

    await _save(nextNotifications);
  }

  Future<void> removeByDoseId(String doseId) async {
    final notifications = await loadPending();
    await _save(notifications.where((item) => item.dose.id != doseId).toList());
  }

  Future<void> _save(List<PendingMissedDoseNotification> notifications) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(
      _storageKey,
      notifications.map((item) => jsonEncode(item.toJson())).toList(),
    );
  }
}
