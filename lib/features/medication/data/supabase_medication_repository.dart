import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:clinic_go/features/medication/models/medication.dart';
import 'package:clinic_go/features/medication/models/medication_reminder.dart';
import 'package:clinic_go/features/medication/data/medication_repository.dart';

class SupabaseMedicationRepository implements MedicationRepository {
  SupabaseMedicationRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<SavedMedicationResult> addMedication(
    AddMedicationPayload payload,
  ) async {
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
          'dosage': payload.dosageAmount,
          'dosage_unit': payload.dosageUnit,
          'frequency': payload.frequency,
          'color': Medication.colorToHex(payload.color),
          'with_food': payload.withFood,
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

    // ── Step 2: Bulk insert reminder rows and read back saved IDs ───
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

      final savedRows = await _client
          .from('medication_reminders')
          .insert(reminderRows)
          .select();

      final savedReminders = (savedRows as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(MedicationReminder.fromJson)
          .toList();

      return SavedMedicationResult(
        medicationId: newMedicationId,
        reminders: savedReminders,
      );
    } catch (e, stackTrace) {
      debugPrint('Error saving reminders: $e\n$stackTrace');
      // ── Rollback: remove the orphaned medication ──────────────────
      try {
        await deleteMedication(newMedicationId);
      } catch (rollbackError) {
        debugPrint('Rollback failed: $rollbackError');
      }
      throw MedicationSaveException('Reminders could not be saved: $e');
    }
  }

  @override
  Future<List<Medication>> fetchMedications() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const MedicationSaveException(
        'Authentication is required to fetch medications.',
      );
    }

    final response = await _client
        .from('medications')
        .select('*, medication_reminders(*)')
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return (response as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(Medication.fromJson)
        .toList();
  }

  @override
  Future<void> editMedication(EditMedicationPayload payload) async {
    // 1. Update main medication row
    await _client
        .from('medications')
        .update({
          'name': payload.name,
          'dosage': payload.dosageAmount,
          'dosage_unit': payload.dosageUnit,
          'frequency': payload.frequency,
          'color': Medication.colorToHex(payload.color),
          'with_food': payload.withFood,
          'start_date': payload.startDate?.toIso8601String().substring(0, 10),
          'end_date': payload.endDate?.toIso8601String().substring(0, 10),
          'notes': payload.notes,
        })
        .eq('id', payload.medicationId);

    // 2. Upsert modified / new reminders
    if (payload.remindersToUpsert.isNotEmpty) {
      await _client
          .from('medication_reminders')
          .upsert(payload.remindersToUpsert);
    }

    // 3. Delete removed reminders
    if (payload.remindersToDelete.isNotEmpty) {
      await _client
          .from('medication_reminders')
          .delete()
          .inFilter('id', payload.remindersToDelete);
    }
  }

  @override
  Future<void> deleteMedication(String id) async {
    await _client.from('medications').delete().eq('id', id);
  }

  @override
  Future<List<MedicationReminder>> fetchAllReminders() async {
    final response = await _client.from('medication_reminders').select();

    return (response as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(MedicationReminder.fromJson)
        .toList();
  }

  @override
  Future<List<MedicationReminder>> fetchRemindersForMedication(
    String medicationId,
  ) async {
    final response = await _client
        .from('medication_reminders')
        .select()
        .eq('medication_id', medicationId);

    return (response as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(MedicationReminder.fromJson)
        .toList();
  }
}
