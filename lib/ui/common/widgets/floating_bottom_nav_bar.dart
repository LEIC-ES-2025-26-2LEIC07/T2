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
      bottom: 30,
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(35),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(Icons.person_outline, 0),
            _buildNavItem(Icons.favorite_border, 1),
            _buildNavItem(Icons.home_outlined, 2),
            _buildNavItem(Icons.calendar_today_outlined, 3),
            _buildNavItem(Icons.settings_outlined, 4),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    final isSelected = currentIndex == index;
    return IconButton(
      icon: Icon(
        icon,
        color: isSelected ? Colors.black : Colors.black45,
        size: isSelected ? 30 : 26,
      ),
      onPressed: () => onTap(index),
    );
  }
}
