import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xFFF8F8F8);
  static const white = Colors.white;
  static const grey = Colors.grey;
  static const shadow = Colors.black12;
  static const primaryColor = Colors.blue;
  static const ink = Color(0xFF182126);
  static const muted = Color(0xFF66727D);

  static Color severityColor(int severity) {
    if (severity <= 3) return const Color(0xFF2E8B57);
    if (severity <= 6) return const Color(0xFFF5A623);
    if (severity <= 8) return const Color(0xFFF26B38);
    return const Color(0xFFD64545);
  }
}
