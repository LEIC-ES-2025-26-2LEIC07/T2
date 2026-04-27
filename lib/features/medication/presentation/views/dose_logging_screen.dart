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

    return Scaffold(
      appBar: AppBar(title: const Text('Dose Logging')),
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
                  'This dose is overdue. Please log whether it was taken or skipped.',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            if (widget.isOverdue) const SizedBox(height: 16),
            Text(
              widget.dose.medicationName,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text('${widget.dose.dosage} scheduled for $scheduledLabel'),
            const SizedBox(height: 24),
            if (_completedStatus == null) ...[
              FilledButton(
                onPressed: _isSubmitting
                    ? null
                    : () => _logDose(
                        context,
                        status: DoseLogStatus.taken,
                        successMessage: 'Dose marked as taken.',
                      ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Mark as Taken'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _isSubmitting
                    ? null
                    : () => _logDose(
                        context,
                        status: DoseLogStatus.skipped,
                        successMessage: 'Dose marked as skipped.',
                      ),
                child: const Text('Skip Dose'),
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
                          ? 'Marked as taken at ${_completedAt != null ? TimeOfDay.fromDateTime(_completedAt!).format(context) : ''}'
                          : 'Marked as skipped at ${_completedAt != null ? TimeOfDay.fromDateTime(_completedAt!).format(context) : ''}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
                child: const Text('Done'),
              ),
            ],
          ],
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

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(successMessage)));
      Navigator.of(context).pop(true);
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
          'We could not save this dose right now. Please try again.';
      if (e is StateError && e.message.contains('Authentication')) {
        message = 'You must be signed in to log doses.';
      } else if (e is SocketException) {
        message = 'Network error. Please check your connection and try again.';
      }

      debugPrint('DoseLoggingScreen._logDose error: $e');
      debugPrintStack(stackTrace: st);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }
}
