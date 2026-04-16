import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/scheduled_dose.dart';

abstract class DoseLogRepository {
  Future<void> logDose({
    required String medicationId,
    required DateTime scheduledTime,
    required DateTime loggedAt,
    required DoseStatus status,
  });
}

class SupabaseDoseLogRepository implements DoseLogRepository {
  SupabaseDoseLogRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<void> logDose({
    required String medicationId,
    required DateTime scheduledTime,
    required DateTime loggedAt,
    required DoseStatus status,
  }) {
    return _client.from('dose_logs').insert({
      'medication_id': medicationId,
      'scheduled_time': scheduledTime.toIso8601String(),
      'taken_time': loggedAt.toIso8601String(),
      'status': status.name,
    });
  }
}

class NoopDoseLogRepository implements DoseLogRepository {
  const NoopDoseLogRepository();

  @override
  Future<void> logDose({
    required String medicationId,
    required DateTime scheduledTime,
    required DateTime loggedAt,
    required DoseStatus status,
  }) async {}
}
