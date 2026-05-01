import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:clinic_go/features/medication/services/pending_notification_store.dart';
import 'package:clinic_go/features/medication/models/pending_missed_dose_notification.dart';
import 'package:clinic_go/features/medication/models/scheduled_dose.dart';

const _storageKey = 'pending_missed_dose_notifications';

final _demoNotification = PendingMissedDoseNotification(
  dose: ScheduledDose(
    id: 'dose-1',
    medicationId: 'med-1',
    medicationName: 'Aspirin',
    dosage: '100mg',
    scheduledTime: DateTime(2026, 4, 16, 8),
  ),
  notificationId: 42,
  scheduledTime: DateTime(2026, 4, 16, 8, 30),
);

final _otherNotification = PendingMissedDoseNotification(
  dose: ScheduledDose(
    id: 'dose-2',
    medicationId: 'med-2',
    medicationName: 'Ibuprofen',
    dosage: '200mg',
    scheduledTime: DateTime(2026, 4, 16, 10),
  ),
  notificationId: 99,
  scheduledTime: DateTime(2026, 4, 16, 10, 30),
);

void main() {
  late PendingNotificationStore store;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    store = const PendingNotificationStore();
  });

  group('PendingNotificationStore', () {
    group('loadPending', () {
      test('loadPending: empty prefs → returns empty list', () async {
        final result = await store.loadPending();
        expect(result, isEmpty);
      });

      test(
        'loadPending: prefs contain one notification → returns it with correct fields',
        () async {
          SharedPreferences.setMockInitialValues({
            _storageKey: [jsonEncode(_demoNotification.toJson())],
          });

          final result = await store.loadPending();

          expect(result, hasLength(1));
          expect(result.first.dose.id, 'dose-1');
          expect(result.first.notificationId, 42);
          expect(result.first.scheduledTime, DateTime(2026, 4, 16, 8, 30));
        },
      );

      test('loadPending: malformed JSON in prefs → throws', () async {
        SharedPreferences.setMockInitialValues({
          _storageKey: ['not valid json {{{{'],
        });

        expect(() => store.loadPending(), throwsA(anything));
      });
    });

    group('upsert', () {
      test(
        'upsert: new notification on empty store → loadPending returns 1 item',
        () async {
          await store.upsert(_demoNotification);

          final result = await store.loadPending();
          expect(result, hasLength(1));
          expect(result.first.dose.id, 'dose-1');
        },
      );

      test(
        'upsert: same doseId → replaces existing entry, count stays at 1',
        () async {
          await store.upsert(_demoNotification);

          final updated = PendingMissedDoseNotification(
            dose: _demoNotification.dose,
            notificationId: 999,
            scheduledTime: _demoNotification.scheduledTime,
          );
          await store.upsert(updated);

          final result = await store.loadPending();
          expect(result, hasLength(1));
          expect(result.first.notificationId, 999);
        },
      );

      test('upsert: different doseId → both entries coexist', () async {
        await store.upsert(_demoNotification);
        await store.upsert(_otherNotification);

        final result = await store.loadPending();
        expect(result, hasLength(2));
        final ids = result.map((n) => n.dose.id).toSet();
        expect(ids, containsAll(['dose-1', 'dose-2']));
      });
    });

    group('removeByDoseId', () {
      test(
        'removeByDoseId: existing doseId → removed, loadPending returns empty',
        () async {
          await store.upsert(_demoNotification);

          await store.removeByDoseId('dose-1');

          final result = await store.loadPending();
          expect(result, isEmpty);
        },
      );

      test(
        'removeByDoseId: non-existent doseId → no error, other items remain',
        () async {
          await store.upsert(_demoNotification);

          await store.removeByDoseId('dose-999');

          final result = await store.loadPending();
          expect(result, hasLength(1));
          expect(result.first.dose.id, 'dose-1');
        },
      );
    });
  });
}
