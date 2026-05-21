import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:clinic_go/core/themes/app_colors.dart';
import 'package:clinic_go/features/home/presentation/view_models/home_view_model.dart';

class HomeEmptyPlanCard extends StatelessWidget {
  const HomeEmptyPlanCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: BrutalDecor.border,
        borderRadius: BorderRadius.circular(20),
        boxShadow: BrutalDecor.shadow,
      ),
      child: const Text(
        'Sem doses agendadas para hoje.',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
        ),
      ),
    );
  }
}

class HomeTodayPlanCard extends StatelessWidget {
  const HomeTodayPlanCard({
    super.key,
    required this.entries,
    required this.now,
  });

  final List<TodayDoseEntry> entries;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        border: BrutalDecor.border,
        borderRadius: BorderRadius.circular(20),
        boxShadow: BrutalDecor.shadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: List.generate(entries.length, (i) {
          return Container(
            decoration: i == 0
                ? null
                : const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: AppColors.paper, width: 2),
                    ),
                  ),
            child: HomeTodayPlanRow(entry: entries[i], now: now),
          );
        }),
      ),
    );
  }
}

class HomeTodayPlanRow extends StatelessWidget {
  const HomeTodayPlanRow({super.key, required this.entry, required this.now});
  final TodayDoseEntry entry;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final timeLabel = DateFormat.Hm().format(entry.dose.scheduledTime);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: _dotColor(),
              border: BrutalDecor.border,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 50,
            child: Text(
              timeLabel,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.1,
                color: AppColors.ink,
              ),
            ),
          ),
          Expanded(
            child: Text(
              '${entry.dose.medicationName} ${entry.dose.dosage}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.1,
                color: AppColors.ink,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          _statusBadge(),
        ],
      ),
    );
  }

  Color _dotColor() {
    if (!entry.isPending) return AppColors.mint;
    if (entry.isOverdue) return AppColors.coral;
    return AppColors.lemon;
  }

  Widget _statusBadge() {
    final Color bg;
    final String label;

    if (!entry.isPending) {
      bg = AppColors.mint;
      label = 'FEITO';
    } else if (entry.isOverdue) {
      bg = AppColors.coral;
      label = 'EM ATRASO';
    } else {
      final minutes = entry.dose.scheduledTime.difference(now).inMinutes;
      if (minutes < 60) {
        bg = AppColors.lemon;
        label = 'EM ${minutes}m';
      } else {
        final hours = minutes ~/ 60;
        if (hours >= 20) {
          bg = AppColors.card;
          label = 'ESTA NOITE';
        } else {
          bg = AppColors.lemon;
          label = 'EM ${hours}h';
        }
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        border: BrutalDecor.border,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.0,
          color: AppColors.ink,
        ),
      ),
    );
  }
}
