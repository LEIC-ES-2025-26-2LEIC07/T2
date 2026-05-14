import 'package:flutter/material.dart';
import 'package:clinic_go/core/themes/app_colors.dart';

class FloatingBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const FloatingBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 12,
      right: 12,
      bottom: 14,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          border: BrutalDecor.border,
          borderRadius: BorderRadius.circular(22),
          boxShadow: BrutalDecor.shadow,
        ),
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            _NavItem(
              index: 0,
              currentIndex: currentIndex,
              label: 'PROFILE',
              icon: _ProfileIcon(),
              onTap: onTap,
            ),
            _NavItem(
              index: 1,
              currentIndex: currentIndex,
              label: 'MEDS',
              icon: _MedsIcon(),
              onTap: onTap,
            ),
            _NavItem(
              index: 2,
              currentIndex: currentIndex,
              label: 'HOME',
              icon: _HomeIcon(),
              onTap: onTap,
            ),
            _NavItem(
              index: 3,
              currentIndex: currentIndex,
              label: 'PLAN',
              icon: _CalIcon(),
              onTap: onTap,
            ),
            _NavItem(
              index: 4,
              currentIndex: currentIndex,
              label: 'SETTINGS',
              icon: _SettingsIcon(),
              onTap: onTap,
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.index,
    required this.currentIndex,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final int index;
  final int currentIndex;
  final String label;
  final Widget icon;
  final Function(int) onTap;

  @override
  Widget build(BuildContext context) {
    final isActive = index == currentIndex;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 60,
          decoration: BoxDecoration(
            color: isActive ? AppColors.lemon : Colors.transparent,
            border: isActive
                ? BrutalDecor.border
                : const Border.fromBorderSide(
                    BorderSide(color: Colors.transparent, width: 2),
                  ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon,
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Icon widgets (custom SVG-equivalent paths) ─────────────────────────────

class _ProfileIcon extends StatelessWidget {
  const _ProfileIcon();
  @override
  Widget build(BuildContext context) =>
      const Icon(Icons.person_outline, color: AppColors.ink, size: 22);
}

class _MedsIcon extends StatelessWidget {
  const _MedsIcon();
  @override
  Widget build(BuildContext context) =>
      const Icon(Icons.medication_outlined, color: AppColors.ink, size: 22);
}

class _HomeIcon extends StatelessWidget {
  const _HomeIcon();
  @override
  Widget build(BuildContext context) =>
      const Icon(Icons.home_outlined, color: AppColors.ink, size: 22);
}

class _CalIcon extends StatelessWidget {
  const _CalIcon();
  @override
  Widget build(BuildContext context) =>
      const Icon(Icons.calendar_today_outlined, color: AppColors.ink, size: 22);
}

class _SettingsIcon extends StatelessWidget {
  const _SettingsIcon();
  @override
  Widget build(BuildContext context) =>
      const Icon(Icons.settings_outlined, color: AppColors.ink, size: 22);
}
