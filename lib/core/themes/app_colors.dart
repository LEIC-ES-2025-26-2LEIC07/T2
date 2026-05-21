import 'package:flutter/material.dart';

class AppColors {
  // ── Design-spec palette ────────────────────────────────────────────────────
  static const ink = Color(0xFF0E2748); // deep navy — text, borders, shadows
  static const paper = Color(0xFFEEF3FA); // cool off-white background
  static const card = Color(0xFFFFFFFF); // pure white cards
  static const coral = Color(0xFFE0796A); // muted alert / dose card
  static const mint = Color(0xFFB7D8C7); // soft sage — success / log symptom
  static const lemon = Color(0xFF3D6BE0); // PRIMARY BLUE — active states, CTA
  static const sky = Color(0xFFC9DCF7); // pale clinical blue — history
  static const rose = Color(0xFFD9E4F4); // pale steel

  // ── Legacy aliases (kept for compatibility) ────────────────────────────────
  static const background = paper;
  static const white = card;
  static const primaryColor = lemon;
  static const muted = Color(0xFF66727D);
  static const shadow = Colors.black12;

  // ── Status badge colours for today's plan ─────────────────────────────────
  static const overdueRed = coral;
  static const statusTeal = Color(0xFF2A9D8F);
  static const statusNight = Color(0xFF374151);

  // ── Semantic feedback colours ──────────────────────────────────────────────
  static const successGreen = Color(0xFF43A047);
  static const successBgLight = Color(0xFFDFF2E8);
  static const successTextDark = Color(0xFF1A7A4A);
  static const dangerRed = Color(0xFFE53935);
  static const errorBgLight = Color(0xFFFFECEC);
  static const errorTextDark = Color(0xFFC62828);
  static const surfaceWarm = Color(0xFFF7F6F3);

  // ── Dose card (kept for any remaining references) ──────────────────────────
  static const doseCardBg = coral;
  static const doseCardDark = ink;

  static Color severityColor(int severity) {
    if (severity <= 3) return const Color(0xFF2E8B57);
    if (severity <= 6) return const Color(0xFFF5A623);
    if (severity <= 8) return const Color(0xFFF26B38);
    return coral;
  }
}

// ── Shared decoration helpers ──────────────────────────────────────────────
class BrutalDecor {
  const BrutalDecor._();

  static const Border border = Border.fromBorderSide(
    BorderSide(color: AppColors.ink, width: 2),
  );
  static const Border borderThick = Border.fromBorderSide(
    BorderSide(color: AppColors.ink, width: 2.5),
  );

  static const List<BoxShadow> shadow = [
    BoxShadow(color: AppColors.ink, offset: Offset(4, 4)),
  ];
  static const List<BoxShadow> shadowSm = [
    BoxShadow(color: AppColors.ink, offset: Offset(3, 3)),
  ];

  static BoxDecoration box({
    Color? color,
    double radius = 16,
    bool shadow = true,
  }) => BoxDecoration(
    color: color ?? AppColors.card,
    border: BrutalDecor.border,
    borderRadius: BorderRadius.circular(radius),
    boxShadow: shadow ? BrutalDecor.shadow : null,
  );
}
