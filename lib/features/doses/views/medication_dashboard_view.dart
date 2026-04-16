import 'package:flutter/material.dart';

import '../../../ui/core/themes/app_colors.dart';
import '../models/scheduled_dose.dart';
import '../view_models/daily_doses_controller.dart';

class MedicationDashboardView extends StatelessWidget {
  const MedicationDashboardView({super.key, required this.controller});

  final DailyDosesController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 120, 24, 120),
          children: [
            const _DashboardHeader(),
            const SizedBox(height: 24),
            ...controller.doses.map(
              (dose) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _DoseCard(
                  dose: dose,
                  onStatusSelected: (status) async {
                    await _handleStatusChange(context, dose.id, status);
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleStatusChange(
    BuildContext context,
    String doseId,
    DoseStatus status,
  ) async {
    try {
      await controller.logDose(doseId: doseId, status: status);
    } catch (_) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Network error. Please try logging your dose again.'),
        ),
      );
    }
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final weekday = _weekdayLabel(now.weekday);
    final month = _monthLabel(now.month);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$weekday, ${now.day} $month',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Colors.black54,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Today\'s medication plan',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Colors.black87,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Mark doses as taken or skipped and we will keep your schedule in sync.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.black54, height: 1.4),
        ),
      ],
    );
  }
}

class _DoseCard extends StatelessWidget {
  const _DoseCard({required this.dose, required this.onStatusSelected});

  final ScheduledDose dose;
  final ValueChanged<DoseStatus> onStatusSelected;

  @override
  Widget build(BuildContext context) {
    final isCompleted = dose.isCompleted;
    final badgeColor = switch (dose.status) {
      DoseStatus.pending => const Color(0xFFE9EEF5),
      DoseStatus.taken => const Color(0xFFDCEFD9),
      DoseStatus.skipped => const Color(0xFFF8E2D6),
    };
    final badgeText = switch (dose.status) {
      DoseStatus.pending => 'Pending',
      DoseStatus.taken => 'Taken',
      DoseStatus.skipped => 'Skipped',
    };
    final icon = switch (dose.status) {
      DoseStatus.pending => Icons.schedule_rounded,
      DoseStatus.taken => Icons.check_circle,
      DoseStatus.skipped => Icons.remove_circle,
    };
    final iconColor = switch (dose.status) {
      DoseStatus.pending => AppColors.primaryColor,
      DoseStatus.taken => const Color(0xFF2E7D32),
      DoseStatus.skipped => const Color(0xFFB85C38),
    };

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: isCompleted ? 0.85 : 1,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: iconColor),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dose.medicationName,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_formatTime(dose.scheduledTime)} • ${dose.dosage}',
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                _StatusBadge(label: badgeText, color: badgeColor),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              dose.instructions,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.black87),
            ),
            const SizedBox(height: 18),
            if (isCompleted)
              Text(
                dose.status == DoseStatus.taken
                    ? 'Logged at ${_formatTime(dose.loggedAt ?? dose.scheduledTime)}'
                    : 'Marked as skipped at ${_formatTime(dose.loggedAt ?? dose.scheduledTime)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.black54,
                  fontWeight: FontWeight.w600,
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => onStatusSelected(DoseStatus.taken),
                      icon: const Icon(Icons.check),
                      label: const Text('Take'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => onStatusSelected(DoseStatus.skipped),
                      icon: const Icon(Icons.close),
                      label: const Text('Skip'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

String _formatTime(DateTime dateTime) {
  final hours = dateTime.hour.toString().padLeft(2, '0');
  final minutes = dateTime.minute.toString().padLeft(2, '0');
  return '$hours:$minutes';
}

String _weekdayLabel(int weekday) {
  const weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  return weekdays[weekday - 1];
}

String _monthLabel(int month) {
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return months[month - 1];
}
