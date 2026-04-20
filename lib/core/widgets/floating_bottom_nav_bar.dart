import 'package:flutter/material.dart';

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
      left: 20,
      right: 20,
      bottom: 20,
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.85), // Glassmorphism base
          borderRadius: BorderRadius.circular(35),
          border: Border.all(color: Colors.white, width: 2), // Clean outline
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(0, Icons.person_outline),
            _buildNavItem(1, Icons.medication_outlined),
            _buildNavItem(2, Icons.home_outlined),
            _buildNavItem(3, Icons.calendar_today_outlined),
            _buildNavItem(4, Icons.settings_outlined),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon) {
    final isSelected = currentIndex == index;
    return IconButton(
      icon: Icon(
        icon,
        color: isSelected
            ? Colors.black
            : const Color(0xFFB0B0B0), // Grey for inactive, black for active
        size: 30,
      ),
      onPressed: () => onTap(index),
    );
  }
}
