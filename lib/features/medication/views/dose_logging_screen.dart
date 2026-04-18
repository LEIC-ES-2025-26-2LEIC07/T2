import 'package:flutter/material.dart';

import '../data/dose_log_repository.dart';
import '../models/scheduled_dose.dart';
import '../services/missed_dose_notification_controller.dart';

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
    setState(() {
      _isSubmitting = true;
    });

    try {
      await widget.controller.logDose(dose: widget.dose, status: status);
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(successMessage)));
    } catch (_) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'We could not save this dose right now. Please try again.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}
