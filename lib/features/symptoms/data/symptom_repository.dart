import 'package:clinic_go/core/providers/supabase_providers.dart';
import 'package:clinic_go/features/symptoms/models/symptom_log.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final symptomRepositoryProvider = Provider<SymptomRepository>((ref) {
  return SymptomRepository(ref.watch(supabaseClientProvider));
});

class SymptomRepository {
  SymptomRepository(this._client);

  final SupabaseClient _client;

  Future<void> insertSymptomLog({
    required String userId,
    required String symptomType,
    required int severity,
    String? notes,
    required DateTime occurredAt,
  }) async {
    final symptomRows = await _client
        .from('symptoms')
        .select('id')
        .eq('name', symptomType)
        .limit(1);
    final symptomId = symptomRows.isEmpty
        ? null
        : symptomRows.first['id'] as String;

    await _client.from('symptom_logs').insert({
      'user_id': userId,
      'symptom_id': symptomId,
      'custom_symptom': symptomId == null ? symptomType : null,
      'severity': severity,
      'notes': notes?.trim().isEmpty == true ? null : notes?.trim(),
      'occurred_at': occurredAt.toUtc().toIso8601String(),
    });
  }

  Future<List<SymptomLog>> fetchSymptomLogs() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      return const [];
    }

    final response = await _client
        .from('symptom_logs')
        .select('*, symptoms(name)')
        .eq('user_id', user.id)
        .order('occurred_at', ascending: false);

    return response
        .map<SymptomLog>(
          (item) => SymptomLog.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }
}
