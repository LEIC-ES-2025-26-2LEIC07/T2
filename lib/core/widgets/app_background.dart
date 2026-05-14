import 'package:flutter/material.dart';

class AppBackground extends StatelessWidget {
  final Widget child;
  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: Color(0xFFF0F4F8),
          image: DecorationImage(
            image: AssetImage('assets/images/wallpaper-paper.png'),
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
        ),
        child: child,
      ),
    );
  }
}
