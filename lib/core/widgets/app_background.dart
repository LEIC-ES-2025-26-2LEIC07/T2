import 'package:flutter/material.dart';

class AppBackground extends StatelessWidget {
  const AppBackground({
    super.key,
    required this.child,
    this.wallpaper = 'assets/images/wallpaper-paper.png',
  });

  final Widget child;
  final String wallpaper;

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFF0F4F8),
          image: DecorationImage(
            image: AssetImage(wallpaper),
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
        ),
        child: child,
      ),
    );
  }
}
