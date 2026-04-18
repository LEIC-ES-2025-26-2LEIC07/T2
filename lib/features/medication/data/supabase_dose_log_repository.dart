import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/scheduled_dose.dart';
import 'dose_log_repository.dart';

class SupabaseDoseLogRepository implements DoseLogRepository {
  SupabaseDoseLogRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<void> insertDoseLog({
    required ScheduledDose dose,
    required DoseLogStatus status,
    required DateTime loggedAt,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('Authentication is required to log a dose.');
    }

    await _client.from('dose_logs').insert({
      'dose_id': dose.id,
      'medication_id': dose.medicationId,
      'status': status.name,
      'scheduled_time': dose.scheduledTime.toIso8601String(),
      'taken_time': loggedAt.toIso8601String(),
      'user_id': user.id,
    });
  }

  @override
  Future<bool> hasDoseLog(String doseId) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      return false;
    }

    final response = await _client
        .from('dose_logs')
        .select('dose_id')
        .eq('user_id', user.id)
        .eq('dose_id', doseId)
        .or('status.eq.taken,status.eq.skipped')
        .limit(1);

    return response.isNotEmpty;
  }
}
