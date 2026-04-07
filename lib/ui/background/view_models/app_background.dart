import 'package:flutter/material.dart';

class AppBackground extends StatelessWidget {
  final Widget child;
  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(
        0xFFF4F4F4,
      ), // Slightly off-white background matching the image
      child: CustomPaint(painter: TopographicPainter(), child: child),
    );
  }
}

class TopographicPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // Draw some smooth curves to simulate topography
    for (int i = 0; i < 20; i++) {
      final path = Path();
      double startY = -100.0 + (i * 60);
      path.moveTo(0, startY);

      // Control points for bezier curve to look like map contours
      path.cubicTo(
        getSizeX(size, 0.3),
        startY + 150 + (i * 5),
        getSizeX(size, 0.6),
        startY - 50 + (i * 2),
        size.width,
        startY + 100,
      );

      final path2 = Path();
      double startY2 = 200.0 + (i * 80);
      path2.moveTo(0, startY2);
      path2.cubicTo(
        getSizeX(size, 0.4),
        startY2 - 200 - (i * 5),
        getSizeX(size, 0.7),
        startY2 + 100 - (i * 2),
        size.width,
        startY2 - 50,
      );

      canvas.drawPath(path, paint);
      canvas.drawPath(path2, paint);
    }

    // Adding some circular contour-like shapes in the corners
    for (int i = 0; i < 5; i++) {
      canvas.drawCircle(
        Offset(size.width * 0.8, size.height * 0.7),
        50.0 + (i * 40),
        paint,
      );
    }
  }

  double getSizeX(Size size, double percent) => size.width * percent;

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
