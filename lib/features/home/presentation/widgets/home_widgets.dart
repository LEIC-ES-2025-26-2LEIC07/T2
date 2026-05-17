import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:clinic_go/core/themes/app_colors.dart';
import 'package:clinic_go/core/widgets/clinic_go_logo.dart';
import 'package:clinic_go/features/medication/data/dose_log_repository.dart';
import 'package:clinic_go/features/medication/models/scheduled_dose.dart';
import 'package:clinic_go/features/home/presentation/view_models/home_view_model.dart';

class HomeHeaderBar extends StatelessWidget {
  const HomeHeaderBar({super.key, this.onGoToMeds});
  final VoidCallback? onGoToMeds;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: onGoToMeds, child: const ClinicGoLogo());
  }
}

class HomeNextDoseCard extends StatelessWidget {
  const HomeNextDoseCard({
    super.key,
    required this.viewModel,
    required this.nextDose,
    required this.isOverdue,
    required this.now,
    required this.onGoToDailyDoses,
  });

  final HomeViewModel viewModel;
  final ScheduledDose? nextDose;
  final bool isOverdue;
  final DateTime now;
  final VoidCallback onGoToDailyDoses;

  @override
  Widget build(BuildContext context) {
    if (nextDose == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.mint,
          border: BrutalDecor.border,
          borderRadius: BorderRadius.circular(22),
          boxShadow: BrutalDecor.shadow,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.paper,
                border: BrutalDecor.border,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.check, color: AppColors.ink, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                viewModel.hadDosesToday
                    ? 'Tudo feito por hoje!'
                    : 'Sem doses agendadas.',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final overdueMinutes = isOverdue
        ? now.difference(nextDose!.scheduledTime).inMinutes
        : 0;
    final timeLabel = DateFormat.Hm().format(nextDose!.scheduledTime);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.coral,
        border: BrutalDecor.border,
        borderRadius: BorderRadius.circular(22),
        boxShadow: BrutalDecor.shadow,
      ),
      child: Stack(
        children: [
          if (isOverdue)
            Positioned(
              top: 14,
              right: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.ink,
                  border: BrutalDecor.border,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'EM ATRASO · ${overdueMinutes}m',
                  style: const TextStyle(
                    color: AppColors.paper,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PRÓXIMA DOSE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.6,
                    color: AppColors.ink,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.paper,
                        border: BrutalDecor.border,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: SizedBox(
                          width: 30,
                          height: 30,
                          child: CustomPaint(painter: HomePillIconPainter()),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 2, right: 80),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${nextDose!.medicationName} ${nextDose!.dosage}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                                color: AppColors.ink,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isOverdue
                                  ? 'Era às $timeLabel'
                                  : 'Agendado às $timeLabel',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.ink.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: HomeBrutalButton(
                        label: 'Tomar agora',
                        bg: AppColors.ink,
                        fg: AppColors.paper,
                        shadowColor: AppColors.paper,
                        onPressed: viewModel.isLoggingDose
                            ? null
                            : () async {
                                try {
                                  await viewModel.logDose(
                                    dose: nextDose!,
                                    status: DoseLogStatus.taken,
                                  );
                                } catch (_) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Não foi possível guardar. Tente novamente.',
                                      ),
                                    ),
                                  );
                                }
                              },
                        isLoading: viewModel.isLoggingDose,
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 110,
                      child: HomeBrutalButton(
                        label: 'Saltar',
                        bg: AppColors.paper,
                        fg: AppColors.ink,
                        onPressed: viewModel.isLoggingDose
                            ? null
                            : () async {
                                try {
                                  await viewModel.logDose(
                                    dose: nextDose!,
                                    status: DoseLogStatus.skipped,
                                  );
                                } catch (_) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Não foi possível guardar. Tente novamente.',
                                      ),
                                    ),
                                  );
                                }
                              },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class HomeQuickActionBox extends StatelessWidget {
  const HomeQuickActionBox({
    super.key,
    required this.bg,
    required this.icon,
    required this.label,
    required this.sub,
    required this.onTap,
  });

  final Color bg;
  final Widget icon;
  final String label;
  final String sub;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
        decoration: BoxDecoration(
          color: bg,
          border: BrutalDecor.border,
          borderRadius: BorderRadius.circular(18),
          boxShadow: BrutalDecor.shadowSm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.paper,
                border: BrutalDecor.border,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(child: icon),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.1,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              sub,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.ink.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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

class HomeBrutalButton extends StatelessWidget {
  const HomeBrutalButton({
    super.key,
    required this.label,
    required this.bg,
    required this.fg,
    this.shadowColor,
    this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final Color bg;
  final Color fg;
  final Color? shadowColor;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final shadow = shadowColor ?? AppColors.paper;
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: onPressed == null
              ? AppColors.paper.withValues(alpha: 0.3)
              : bg,
          border: BrutalDecor.border,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: shadow, offset: const Offset(3, 3))],
        ),
        child: Center(
          child: isLoading
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: fg),
                )
              : Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.1,
                    color: fg,
                  ),
                ),
        ),
      ),
    );
  }
}

class HomePillIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.coral
      ..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = AppColors.paper
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, size.height * 0.33, size.width, size.height * 0.34),
      Radius.circular(size.height * 0.17),
    );
    canvas.drawRRect(rrect, paint);
    canvas.drawRRect(rrect, stroke);
    canvas.drawLine(
      Offset(size.width / 2, size.height * 0.33),
      Offset(size.width / 2, size.height * 0.67),
      stroke,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
