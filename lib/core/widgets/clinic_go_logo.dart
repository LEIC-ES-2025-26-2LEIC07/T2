import 'package:flutter/material.dart';
import 'package:clinic_go/core/themes/app_colors.dart';

/// Reusable ClinicGO brand header: blue cross tile + "ClinicGO" wordmark.
class ClinicGoLogo extends StatelessWidget {
  const ClinicGoLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.lemon,
            border: BrutalDecor.border,
            borderRadius: BorderRadius.circular(10),
            boxShadow: BrutalDecor.shadowSm,
          ),
          child: Center(
            child: SizedBox(
              width: 18,
              height: 18,
              child: CustomPaint(painter: _CrossPainter()),
            ),
          ),
        ),
        const SizedBox(width: 10),
        const Text(
          'ClinicGO',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
            color: AppColors.ink,
          ),
        ),
      ],
    );
  }
}

class _CrossPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.card
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 7 / 18,
          size.height * 2 / 18,
          size.width * 4 / 18,
          size.height * 14 / 18,
        ),
        const Radius.circular(1),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 2 / 18,
          size.height * 7 / 18,
          size.width * 14 / 18,
          size.height * 4 / 18,
        ),
        const Radius.circular(1),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
