import 'package:flutter/material.dart';
import 'package:clinic_go/core/themes/app_colors.dart';

class MedListEmptyState extends StatelessWidget {
  const MedListEmptyState({super.key, required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.medication_outlined,
            size: 64,
            color: Color(0xFFB0B0B0),
          ),
          const SizedBox(height: 16),
          const Text(
            'Nenhum medicamento',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Toque em Adicionar para começar.',
            style: TextStyle(color: Colors.black38),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: onAdd,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BrutalDecor.box(color: AppColors.lemon, radius: 30),
              child: const Text(
                'Adicionar medicamento',
                style: TextStyle(
                  color: AppColors.card,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MedListErrorState extends StatelessWidget {
  const MedListErrorState({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class MedListAddButton extends StatelessWidget {
  const MedListAddButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BrutalDecor.box(color: AppColors.lemon, radius: 30),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, color: AppColors.card, size: 18),
            SizedBox(width: 4),
            Text(
              'Adicionar',
              style: TextStyle(
                color: AppColors.card,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
