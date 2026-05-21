import 'package:flutter/material.dart';
import 'package:clinic_go/core/themes/app_colors.dart';

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
