import 'package:flutter/material.dart';
import 'package:clinic_go/features/medication/models/medication.dart';
import 'package:clinic_go/features/medication/models/medication_reminder.dart';

/// Payload for the two-step medication + reminders insertion.
class AddMedicationPayload {
  const AddMedicationPayload({
    required this.name,
    required this.dosageAmount,
    required this.dosageUnit,
    required this.frequency,
    required this.color,
    required this.reminderTimes,
    required this.daysOfWeek,
    this.startDate,
    this.endDate,
    this.notes,
    this.withFood = false,
  });

  final String name;
  final int dosageAmount;
  final String dosageUnit;
  final String frequency;
  final Color color;

  /// 'HH:mm:ss' strings — one per reminder slot.
  final List<String> reminderTimes;

  /// Day-of-week names matching Postgres TEXT[], e.g. ['monday', 'friday'].
  final List<String> daysOfWeek;

  final DateTime? startDate;
  final DateTime? endDate;
  final String? notes;
  final bool withFood;
}

/// Thrown when the two-step insert fails and a client-side rollback is performed.
class MedicationSaveException implements Exception {
  const MedicationSaveException(this.message);
  final String message;

  @override
  String toString() => 'MedicationSaveException: $message';
}

/// Returned by [MedicationRepository.addMedication] — carries both the new
/// medication UUID and the saved reminders (which now have Supabase-assigned IDs).
class SavedMedicationResult {
  const SavedMedicationResult({
    required this.medicationId,
    required this.reminders,
  });

  final String medicationId;
  final List<MedicationReminder> reminders;
}

/// Payload for the multi-step medication edit operation.
class EditMedicationPayload {
  const EditMedicationPayload({
    required this.medicationId,
    required this.name,
    required this.dosageAmount,
    required this.dosageUnit,
    required this.frequency,
    required this.color,
    required this.daysOfWeek,
    required this.remindersToUpsert,
    required this.remindersToDelete,
    this.startDate,
    this.endDate,
    this.notes,
    this.withFood = false,
  });

  final String medicationId;
  final String name;
  final int dosageAmount;
  final String dosageUnit;
  final String frequency;
  final Color color;
  final List<String> daysOfWeek;

  /// Each map must contain 'medication_id', 'reminder_time', 'days_of_week',
  /// 'is_active', and optionally 'id' (present for existing reminders).
  final List<Map<String, dynamic>> remindersToUpsert;

  /// UUIDs of reminders to hard-delete.
  final List<String> remindersToDelete;

  final DateTime? startDate;
  final DateTime? endDate;
  final String? notes;
  final bool withFood;
}

/// Abstract repository — keeps ViewModels and tests independent of Supabase.
abstract class MedicationRepository {
  /// Inserts a medication + its reminders (with rollback on failure).
  /// Returns the new medication UUID and saved reminders (with real IDs).
  Future<SavedMedicationResult> addMedication(AddMedicationPayload payload);

  /// Multi-step edit: UPDATE medication, UPSERT reminders, DELETE removed ones.
  Future<void> editMedication(EditMedicationPayload payload);

  /// Fetches all medications for the authenticated user (newest first).
  Future<List<Medication>> fetchMedications();

  /// Hard-deletes a medication by UUID (cascades to reminders and logs via DB).
  Future<void> deleteMedication(String id);

  /// Fetches all reminders for the authenticated user.
  Future<List<MedicationReminder>> fetchAllReminders();

  /// Fetches reminders for a single medication.
  Future<List<MedicationReminder>> fetchRemindersForMedication(
    String medicationId,
  );
}
