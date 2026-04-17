import 'package:clinic_go/ui/core/themes/app_colors.dart';
import 'package:clinic_go/ui/home/models/scheduled_dose.dart';
import 'package:clinic_go/ui/home/view_models/daily_doses_controller.dart';
import 'package:flutter/material.dart';

Future<void> showDoseLoggingSheet({
  required BuildContext context,
  required DailyDosesController controller,
  required ScheduledDose dose,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return DoseLoggingSheet(controller: controller, dose: dose);
    },
  );
}

class DoseLoggingSheet extends StatelessWidget {
  const DoseLoggingSheet({
    super.key,
    required this.controller,
    required this.dose,
  });

  final DailyDosesController controller;
  final ScheduledDose dose;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              dose.medicationName,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              '${dose.dosage} • ${_formatTime(dose.scheduledTime)}',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black.withValues(alpha: 0.65),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Como queres registar esta toma?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: dose.isCompleted
                        ? null
                        : () => _submit(context, DoseLogStatus.taken),
                    child: const Text('Tomar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: dose.isCompleted
                        ? null
                        : () => _submit(context, DoseLogStatus.skipped),
                    child: const Text('Ignorar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit(BuildContext context, DoseLogStatus status) async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await controller.logDose(
      medicationId: dose.medicationId,
      scheduledTime: dose.scheduledTime,
      status: status,
    );

    if (!context.mounted) {
      return;
    }

    if (result.outcome == DoseLogOutcome.success) {
      Navigator.of(context).pop();
      return;
    }

    if (result.message != null) {
      messenger.showSnackBar(SnackBar(content: Text(result.message!)));
    }
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
