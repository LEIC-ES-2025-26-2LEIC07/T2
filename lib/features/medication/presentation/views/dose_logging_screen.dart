import 'dart:io';

import 'package:flutter/material.dart';

import 'package:clinic_go/features/medication/data/dose_log_repository.dart';
import 'package:clinic_go/features/medication/models/scheduled_dose.dart';
import 'package:clinic_go/features/medication/services/missed_dose_notification_controller.dart';

class DoseLoggingScreen extends StatefulWidget {
  const DoseLoggingScreen({
    super.key,
    required this.dose,
    required this.controller,
    this.isOverdue = false,
  });

  final ScheduledDose dose;
  final MissedDoseNotificationController controller;
  final bool isOverdue;

  @override
  State<DoseLoggingScreen> createState() => _DoseLoggingScreenState();
}

class _DoseLoggingScreenState extends State<DoseLoggingScreen> {
  bool _isSubmitting = false;
  DoseLogStatus? _completedStatus;
  DateTime? _completedAt;

  @override
  Widget build(BuildContext context) {
    final scheduledLabel = TimeOfDay.fromDateTime(
      widget.dose.scheduledTime,
    ).format(context);

    return PopScope(
      canPop: _completedStatus == null && !_isSubmitting,
      onPopInvokedWithResult: (bool didPop, _) {
        if (!didPop && _completedStatus != null && !_isSubmitting) {
          Navigator.of(context).pop(true);
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Registo de Dose')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.isOverdue)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1E5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Esta dose está em atraso. Regista se foi tomada ou ignorada.',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              if (widget.isOverdue) const SizedBox(height: 16),
              Text(
                widget.dose.medicationName,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text('${widget.dose.dosage} agendada para $scheduledLabel'),
              const SizedBox(height: 24),
              if (_completedStatus == null) ...[
                FilledButton(
                  onPressed: _isSubmitting
                      ? null
                      : () => _logDose(
                          context,
                          status: DoseLogStatus.taken,
                          successMessage: 'Dose marcada como tomada.',
                        ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Marcar como Tomada'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _isSubmitting
                      ? null
                      : () => _logDose(
                          context,
                          status: DoseLogStatus.skipped,
                          successMessage: 'Dose marcada como ignorada.',
                        ),
                  child: const Text('Ignorar Dose'),
                ),
              ] else ...[
                Row(
                  children: [
                    Icon(
                      _completedStatus == DoseLogStatus.taken
                          ? Icons.check_circle_outline
                          : Icons.block,
                      color: _completedStatus == DoseLogStatus.taken
                          ? Colors.green
                          : Colors.orange,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _completedStatus == DoseLogStatus.taken
                            ? 'Marcada como tomada às ${_completedAt != null ? TimeOfDay.fromDateTime(_completedAt!).format(context) : ''}'
                            : 'Marcada como ignorada às ${_completedAt != null ? TimeOfDay.fromDateTime(_completedAt!).format(context) : ''}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _isSubmitting
                      ? null
                      : () => Navigator.of(context).pop(true),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Concluído'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _logDose(
    BuildContext context, {
    required DoseLogStatus status,
    required String successMessage,
  }) async {
    // Optimistic UI: mark completed locally immediately
    final now = DateTime.now();
    setState(() {
      _completedStatus = status;
      _completedAt = now;
      _isSubmitting = true;
    });

    try {
      await widget.controller.logDose(
        dose: widget.dose,
        status: status,
        loggedAt: now,
      );
      if (!context.mounted) return;

      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(successMessage)));
    } catch (e, st) {
      // rollback optimistic update
      if (!context.mounted) return;
      setState(() {
        _completedStatus = null;
        _completedAt = null;
        _isSubmitting = false;
      });

      // Provide more specific feedback for common failures
      String message =
          'Não foi possível guardar esta dose agora. Tenta novamente.';
      if (e is StateError && e.message.contains('Authentication')) {
        message = 'Tens de iniciar sessão para registar doses.';
      } else if (e is SocketException) {
        message = 'Erro de rede. Verifica a tua ligação e tenta novamente.';
      }

      debugPrint('DoseLoggingScreen._logDose error: $e');
      debugPrintStack(stackTrace: st);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }
}
