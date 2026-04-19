import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:clinic_go/features/medication/models/medication.dart';
import 'package:clinic_go/features/medication/models/medication_reminder.dart';
import 'package:clinic_go/features/medication/data/medication_repository.dart';

class SupabaseMedicationRepository implements MedicationRepository {
  SupabaseMedicationRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<String> addMedication(AddMedicationPayload payload) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const MedicationSaveException(
        'Authentication is required to add a medication.',
      );
    }

    // ── Step 1: Insert the parent medication row ────────────────────
    final medicationRow = await _client
        .from('medications')
        .insert({
          'user_id': user.id,
          'name': payload.name,
          'dosage': payload.dosage,
          'frequency': payload.frequency,
          'color': Medication.colorToHex(payload.color),
          if (payload.startDate != null)
            'start_date': payload.startDate!.toIso8601String().substring(0, 10),
          if (payload.endDate != null)
            'end_date': payload.endDate!.toIso8601String().substring(0, 10),
          if (payload.notes != null && payload.notes!.isNotEmpty)
            'notes': payload.notes,
        })
        .select('id')
        .single();

    final newMedicationId = medicationRow['id'] as String;

    // ── Step 2: Bulk insert reminder rows ───────────────────────────
    try {
      final reminderRows = payload.reminderTimes
          .map(
            (time) => MedicationReminder(
              medicationId: newMedicationId,
              reminderTime: time,
              daysOfWeek: payload.daysOfWeek,
            ).toInsertJson(),
          )
          .toList();

      await _client.from('medication_reminders').insert(reminderRows);
    } catch (_) {
      // ── Rollback: remove the orphaned medication ──────────────────
      try {
        await deleteMedication(newMedicationId);
      } catch (_) {
        // Best-effort; ignore secondary failures.
      }
      throw const MedicationSaveException(
        'Reminders could not be saved and the medication was rolled back. '
        'Please try again.',
      );
    }

    return newMedicationId;
  }

  @override
  Future<List<Medication>> fetchMedications() async {
    // RLS ensures only the current user's rows are returned.
    final response = await _client
        .from('medications')
        .select()
        .order('created_at', ascending: false);

    return (response as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(Medication.fromJson)
        .toList();
  }

  @override
  Future<void> deleteMedication(String id) async {
    await _client.from('medications').delete().eq('id', id);
  }
}
