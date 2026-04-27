import 'package:flutter/material.dart';
import 'package:clinic_go/features/medication/models/medication.dart';
import 'package:clinic_go/features/medication/models/medication_reminder.dart';

/// Payload for the two-step medication + reminders insertion.
class AddMedicationPayload {
  const AddMedicationPayload({
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.color,
    required this.reminderTimes,
    required this.daysOfWeek,
    this.startDate,
    this.endDate,
    this.notes,
  });

  final String name;
  final String dosage;
  final String frequency;
  final Color color;

  /// 'HH:mm:ss' strings — one per reminder slot.
  final List<String> reminderTimes;

  /// Day-of-week names matching Postgres TEXT[], e.g. ['monday', 'friday'].
  final List<String> daysOfWeek;

  final DateTime? startDate;
  final DateTime? endDate;
  final String? notes;
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

/// Abstract repository — keeps ViewModels and tests independent of Supabase.
abstract class MedicationRepository {
  /// Inserts a medication + its reminders (with rollback on failure).
  /// Returns the new medication UUID and saved reminders (with real IDs).
  Future<SavedMedicationResult> addMedication(AddMedicationPayload payload);

  /// Fetches all medications for the authenticated user (newest first).
  Future<List<Medication>> fetchMedications();

  /// Hard-deletes a medication by UUID (used internally for rollback).
  Future<void> deleteMedication(String id);

  /// Fetches all reminders for the authenticated user.
  Future<List<MedicationReminder>> fetchAllReminders();
}
