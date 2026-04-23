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
    final lastUnderscore = dose.id.lastIndexOf('_');
    final reminderId = dose.id.substring(0, lastUnderscore);

    await _client.from('medication_logs').insert({
      'reminder_id': reminderId,
      'taken_at': loggedAt.toIso8601String(),
      'was_taken': status == DoseLogStatus.taken,
    });
  }

  @override
  Future<bool> hasDoseLog(String doseId) async {
    if (_client.auth.currentUser == null) return false;

    final lastUnderscore = doseId.lastIndexOf('_');
    final reminderId = doseId.substring(0, lastUnderscore);
    final epochSeconds = int.parse(doseId.substring(lastUnderscore + 1));
    final scheduledTime = DateTime.fromMillisecondsSinceEpoch(
      epochSeconds * 1000,
    );
    final dayStart = DateTime(
      scheduledTime.year,
      scheduledTime.month,
      scheduledTime.day,
    );
    final dayEnd = dayStart.add(const Duration(days: 1));

    final response = await _client
        .from('medication_logs')
        .select('id')
        .eq('reminder_id', reminderId)
        .gte('taken_at', dayStart.toIso8601String())
        .lt('taken_at', dayEnd.toIso8601String())
        .limit(1);

    return response.isNotEmpty;
  }
}
