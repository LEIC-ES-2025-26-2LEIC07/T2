import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:clinic_go/core/themes/app_colors.dart';
import 'package:clinic_go/features/medication/data/dose_log_repository.dart';
import 'package:clinic_go/features/medication/models/scheduled_dose.dart';
import 'package:clinic_go/features/home/presentation/view_models/home_view_model.dart';
import 'package:clinic_go/features/home/presentation/widgets/home_brutal_button.dart';

class HomeNextDoseCard extends StatelessWidget {
  const HomeNextDoseCard({
    super.key,
    required this.viewModel,
    required this.nextDose,
    required this.isOverdue,
    required this.now,
    required this.onGoToDailyDoses,
    this.onDoseLogged,
  });

  final HomeViewModel viewModel;
  final ScheduledDose? nextDose;
  final bool isOverdue;
  final DateTime now;
  final VoidCallback onGoToDailyDoses;
  final VoidCallback? onDoseLogged;

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
                                  onDoseLogged?.call();
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
                                  onDoseLogged?.call();
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
