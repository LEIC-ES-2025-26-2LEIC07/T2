import 'dart:io';

import 'package:clinic_go/ui/home/models/dose_log_entry.dart';
import 'package:clinic_go/ui/home/models/scheduled_dose.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class DoseLogsRepository {
  bool get isAuthenticated;

  Future<void> insertDoseLog(DoseLogEntry entry);
}

class UnauthenticatedDoseLogsRepository implements DoseLogsRepository {
  @override
  bool get isAuthenticated => false;

  @override
  Future<void> insertDoseLog(DoseLogEntry entry) {
    throw const DoseLogException(
      'Inicia sessão para registar a toma desta medicação.',
    );
  }
}

class DoseLogException implements Exception {
  const DoseLogException(this.message);

  final String message;
}

class SupabaseDoseLogsRepository implements DoseLogsRepository {
  SupabaseDoseLogsRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  @override
  bool get isAuthenticated => _client.auth.currentUser != null;

  @override
  Future<void> insertDoseLog(DoseLogEntry entry) async {
    if (!isAuthenticated) {
      throw const DoseLogException(
        'Inicia sessão para registar a toma desta medicação.',
      );
    }

    try {
      await _client.from('dose_logs').insert({
        'medication_id': entry.medicationId,
        'scheduled_time': entry.scheduledTime.toIso8601String(),
        'taken_time': entry.loggedAt.toIso8601String(),
        'status': _statusToValue(entry.status),
      });
    } on SocketException {
      throw const DoseLogException(
        'Erro de rede. Tenta novamente para registar a tua toma.',
      );
    } on AuthException {
      throw const DoseLogException(
        'A tua sessão expirou. Entra novamente para continuar.',
      );
    } on PostgrestException catch (error) {
      throw DoseLogException(
        error.message.isEmpty
            ? 'Nao foi possivel guardar o registo da toma.'
            : error.message,
      );
    } catch (_) {
      throw const DoseLogException(
        'Nao foi possivel guardar o registo da toma.',
      );
    }
  }

  String _statusToValue(DoseLogStatus status) {
    switch (status) {
      case DoseLogStatus.pending:
        return 'pending';
      case DoseLogStatus.taken:
        return 'taken';
      case DoseLogStatus.skipped:
        return 'skipped';
    }
  }
}
