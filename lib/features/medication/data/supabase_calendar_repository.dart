import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'calendar_repository.dart';
import 'dose_log_repository.dart';

class SupabaseCalendarRepository implements CalendarRepository {
  SupabaseCalendarRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<DoseLogEntry>> fetchDoseLogs({
    required DateTime from,
    required DateTime to,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('Authentication is required to fetch calendar data.');
    }
    try {
      // medication_logs schema: id, reminder_id, taken_at, was_taken
      // medication_logs table does not store user_id; reminders -> medications
      // link to the owning medication which has user_id. Query logs for the
      // date range (no user filter) and later filter by medication ownership.
      final response = await _client
          .from('medication_logs')
          .select('id, reminder_id, taken_at, was_taken')
          .gte('taken_at', from.toIso8601String())
          .lte('taken_at', to.toIso8601String());

      final List<dynamic> rows = response as List<dynamic>;

      // Collect reminder ids to fetch reminder -> medication mapping.
      final reminderIds = <String>{};
      for (final r in rows) {
        final rid = r['reminder_id'];
        if (rid != null) reminderIds.add(rid.toString());
      }

      Map<String, Map<String, dynamic>> remindersMap = {};
      if (reminderIds.isNotEmpty) {
        final remResp = await _client
            .from('medication_reminders')
            .select('id, medication_id')
            .filter(
              'id',
              'in',
              '(${reminderIds.map((s) => "\"$s\"").join(',')})',
            );
        for (final r in (remResp as List<dynamic>)) {
          final idVal = r['id'];
          if (idVal != null)
            remindersMap[idVal.toString()] = r as Map<String, dynamic>;
        }
      }

      // Fetch medication details for medication_ids (RLS will ensure we only
      // receive medications for the current user)
      final medIds = remindersMap.values
          .map((m) => (m['medication_id'] ?? '').toString())
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();
      final medsMap = <String, Map<String, dynamic>>{};
      if (medIds.isNotEmpty) {
        final medsResp = await _client
            .from('medications')
            .select('id, name, dosage')
            .filter('id', 'in', '(${medIds.map((s) => "\"$s\"").join(',')})');
        for (final m in (medsResp as List<dynamic>)) {
          final idVal = m['id'];
          if (idVal != null)
            medsMap[idVal.toString()] = m as Map<String, dynamic>;
        }
      }

      // Map rows to DoseLogEntry but only include logs whose medication
      // belongs to the current user (medsMap contains only allowed meds).
      final out = <DoseLogEntry>[];
      for (final r in rows) {
        final reminderIdRaw = r['reminder_id'];
        final reminderId = reminderIdRaw != null
            ? reminderIdRaw.toString()
            : null;
        final rem = reminderId != null ? remindersMap[reminderId] : null;
        final med = rem != null
            ? medsMap[(rem['medication_id'] ?? '').toString()]
            : null;
        if (med == null) continue; // not this user's medication

        final takenAtRaw = r['taken_at'];
        DateTime? takenAt;
        if (takenAtRaw is String) {
          takenAt = DateTime.tryParse(takenAtRaw);
        } else if (takenAtRaw is int) {
          takenAt = DateTime.fromMillisecondsSinceEpoch(takenAtRaw * 1000);
        } else if (takenAtRaw is double) {
          takenAt = DateTime.fromMillisecondsSinceEpoch(
            (takenAtRaw * 1000).toInt(),
          );
        }

        final idVal = r['id'];
        final idStr = idVal != null ? idVal.toString() : '';

        out.add(
          DoseLogEntry(
            id: idStr,
            status: (r['was_taken'] as bool?) == true
                ? DoseLogStatus.taken
                : DoseLogStatus.skipped,
            // No scheduled_time stored in medication_logs; use takenAt as the anchor
            scheduledTime: takenAt ?? DateTime.now(),
            takenTime: takenAt,
            medicationId: med['id']?.toString(),
            medicationName: med['name']?.toString(),
            dosage: med['dosage']?.toString(),
          ),
        );
      }

      return out;
    } catch (e, st) {
      debugPrint('SupabaseCalendarRepository.fetchDoseLogs failed: $e');
      debugPrintStack(stackTrace: st);
      rethrow;
    }
  }
}
