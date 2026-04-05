import 'package:flutter/material.dart';
import '../../core/themes/app_colors.dart';

class AppBackground extends StatelessWidget {
  final Widget child;
  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: AppColors.background,
      child: child,
    );
  }
}
