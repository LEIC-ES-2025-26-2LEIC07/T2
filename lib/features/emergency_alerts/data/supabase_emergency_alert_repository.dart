import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/emergency_alert.dart';
import 'emergency_alert_repository.dart';

const _missedDoseTitle = 'Dose esquecida';
const _missedDoseMessageTemplate =
    'Não tomou {dosage} de {medication} às {time}.';

class SupabaseEmergencyAlertRepository implements EmergencyAlertRepository {
  SupabaseEmergencyAlertRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<EmergencyAlert>> fetchUnacknowledgedAlerts() async {
    final user = _client.auth.currentUser;
    if (user == null) return const [];

    final rows = await _client
        .from('alerts')
        .select()
        .eq('user_id', user.id)
        .filter('acknowledged_at', 'is', null)
        .order('created_at', ascending: false);

    return (rows as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(EmergencyAlert.fromJson)
        .toList();
  }

  @override
  Future<EmergencyAlert?> fetchAlert(String id) async {
    final rows = await _client.from('alerts').select().eq('id', id).limit(1);
    if ((rows as List<dynamic>).isEmpty) return null;
    return EmergencyAlert.fromJson(rows.first);
  }

  @override
  Future<void> acknowledgeAlert(String id) async {
    await _client
        .from('alerts')
        .update({'acknowledged_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', id);
  }

  @override
  Stream<EmergencyAlert> watchInsertedAlerts() {
    final controller = StreamController<EmergencyAlert>();

    final channel = _client.channel('public:alerts:emergency');
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'alerts',
          callback: (payload) {
            try {
              controller.add(EmergencyAlert.fromJson(payload.newRecord));
            } catch (e) {
              controller.addError(e);
            }
          },
        )
        .subscribe((status, [error]) {
          if (error != null) controller.addError(error);
        });

    controller.onCancel = () {
      _client.removeChannel(channel);
    };

    return controller.stream;
  }

  @override
  Future<void> syncPushToken(String token, String platform) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    await _client.from('device_push_tokens').upsert({
      'user_id': user.id,
      'token': token,
      'platform': platform,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'token');
  }

  @override
  Future<void> removePushToken(String token) async {
    await _client.from('device_push_tokens').delete().eq('token', token);
  }

  @override
  Future<void> createMissedDoseAlert({
    required String medicationName,
    required String dosage,
    required DateTime scheduledTime,
    String? doseId,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    final timeStr =
        '${scheduledTime.hour.toString().padLeft(2, '0')}:${scheduledTime.minute.toString().padLeft(2, '0')}';

    final message = _missedDoseMessageTemplate
        .replaceAll('{dosage}', dosage)
        .replaceAll('{medication}', medicationName)
        .replaceAll('{time}', timeStr);

    await _client.from('alerts').insert({
      'user_id': user.id,
      'title': _missedDoseTitle,
      'message': message,
      'severity': 'high',
      'metadata': {
        'type': 'missed_dose',
        'medication': medicationName,
        'dose_id': ?doseId,
      },
    });
  }
}
