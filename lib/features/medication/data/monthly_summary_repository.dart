import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:clinic_go/features/medication/models/monthly_medication_log.dart';

class MonthlySummaryRepository {
  const MonthlySummaryRepository(this._client);

  final SupabaseClient _client;

  Future<List<MonthlyMedicationLog>> fetchMonthlyLogs(DateTime month) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('Authentication is required.');
    }

    final start = DateTime(month.year, month.month);
    final nextMonth = DateTime(month.year, month.month + 1);

    final response = await _client
        .from('medication_logs')
        .select(
          'id, was_taken, taken_at, '
          'medication_reminders!inner('
          'medication_id, medications!inner(name, dosage, user_id)'
          ')',
        )
        .eq('medication_reminders.medications.user_id', user.id)
        .gte('taken_at', start.toIso8601String())
        .lt('taken_at', nextMonth.toIso8601String())
        .order('taken_at');

    return (response as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(MonthlyMedicationLog.fromJson)
        .toList();
  }
}
