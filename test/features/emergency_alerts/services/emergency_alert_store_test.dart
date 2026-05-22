import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:clinic_go/features/emergency_alerts/models/emergency_alert.dart';
import 'package:clinic_go/features/emergency_alerts/services/emergency_alert_store.dart';

void main() {
  late EmergencyAlertStore store;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    store = const EmergencyAlertStore();
  });

  group('EmergencyAlertStore', () {
    test('loadUnacknowledged returns empty list when cache is empty', () async {
      expect(await store.loadUnacknowledged(), isEmpty);
    });

    test('upsert persists unresolved alert until it is removed', () async {
      final alert = EmergencyAlert(
        id: 'alert-1',
        title: 'Critical medication overdue',
        message: 'A life-sustaining medication is overdue.',
        createdAt: DateTime(2026, 5, 22, 9),
      );

      await store.upsert(alert);
      final loaded = await store.loadUnacknowledged();

      expect(loaded, hasLength(1));
      expect(loaded.first.id, 'alert-1');
      expect(loaded.first.title, 'Critical medication overdue');

      await store.remove('alert-1');
      expect(await store.loadUnacknowledged(), isEmpty);
    });

    test('replaceAll filters acknowledged alerts', () async {
      await store.replaceAll([
        EmergencyAlert(
          id: 'active',
          title: 'Active',
          message: 'Needs action',
          createdAt: DateTime(2026, 5, 22, 9),
        ),
        EmergencyAlert(
          id: 'done',
          title: 'Done',
          message: 'Already handled',
          createdAt: DateTime(2026, 5, 22, 8),
          acknowledgedAt: DateTime(2026, 5, 22, 8, 10),
        ),
      ]);

      final loaded = await store.loadUnacknowledged();
      expect(loaded.map((alert) => alert.id), ['active']);
    });
  });
}
