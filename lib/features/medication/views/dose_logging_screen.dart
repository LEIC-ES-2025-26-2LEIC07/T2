import 'package:flutter/material.dart';

import '../data/dose_log_repository.dart';
import '../models/scheduled_dose.dart';
import '../services/missed_dose_notification_controller.dart';

class DoseLoggingScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final scheduledLabel = TimeOfDay.fromDateTime(
      dose.scheduledTime,
    ).format(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Dose Logging')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isOverdue)
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
            if (isOverdue) const SizedBox(height: 16),
            Text(
              dose.medicationName,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text('${dose.dosage} scheduled for $scheduledLabel'),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => _logDose(
                context,
                status: DoseLogStatus.taken,
                message: 'Dose marked as taken.',
              ),
              child: const Text('Mark as Taken'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => _logDose(
                context,
                status: DoseLogStatus.skipped,
                message: 'Dose marked as skipped.',
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
    required String message,
  }) async {
    await controller.logDose(dose: dose, status: status);
    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
