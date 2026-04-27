import 'package:flutter/material.dart';
import 'package:clinic_go/core/color_palette/app_colors.dart';

class AppBackground extends StatelessWidget {
  final Widget child;
  final double linePresence;

  const AppBackground({
    super.key,
    required this.child,
    this.linePresence = 0.40,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.white,
          image: DecorationImage(
            image: const AssetImage('assets/images/background_topography.png'),
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
        ),
        child: child,
      ),
    );
  }
}