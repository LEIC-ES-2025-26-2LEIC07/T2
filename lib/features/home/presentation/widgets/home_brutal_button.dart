import 'package:flutter/material.dart';
import 'package:clinic_go/core/themes/app_colors.dart';

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
