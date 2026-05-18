import 'package:flutter/material.dart';

class StatusBanner extends StatelessWidget {
  const StatusBanner({
    super.key,
    required this.message,
    required this.isSuccess,
  });

  final String message;
  final bool isSuccess;

  @override
  Widget build(BuildContext context) {
    final bg = isSuccess ? const Color(0xFFDFF2E8) : const Color(0xFFFFECEC);
    final fg = isSuccess ? const Color(0xFF1A7A4A) : const Color(0xFFC62828);
    final icon = isSuccess ? Icons.check_circle_outline : Icons.error_outline;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: fg, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: fg,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
