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
    await _client.from('dose_logs').insert({
      'dose_id': dose.id,
      'medication_id': dose.medicationId,
      'status': status.name,
      'scheduled_time': dose.scheduledTime.toIso8601String(),
      'taken_time': loggedAt.toIso8601String(),
      'user_id': _client.auth.currentUser?.id,
    });
  }

  @override
  Future<bool> hasDoseLog(String doseId) async {
    final response = await _client
        .from('dose_logs')
        .select('dose_id')
        .eq('dose_id', doseId)
        .limit(1);

    return response.isNotEmpty;
  }
}
