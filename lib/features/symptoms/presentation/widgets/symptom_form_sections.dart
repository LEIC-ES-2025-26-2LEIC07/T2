import 'package:flutter/material.dart';
import 'package:clinic_go/core/themes/app_colors.dart';

// TODO(team): extend this map when new symptom keys are added on the backend.
String _ptLabel(String symptom) {
  const labels = {
    'headache': 'Dor de cabeça',
    'nausea': 'Náusea',
    'fatigue': 'Fadiga',
    'dizziness': 'Tonturas',
    'fever': 'Febre',
    'cough': 'Tosse',
    'shortness_of_breath': 'Falta de ar',
    'anxiety': 'Ansiedade',
    'sadness': 'Tristeza',
    'muscle_pain': 'Dor muscular',
    'joint_pain': 'Dor nas articulações',
    'stomach_pain': 'Dor de estômago',
    'insomnia': 'Insónia',
    'brain_fog': 'Confusão mental',
  };
  final key = symptom.trim().toLowerCase();
  return labels[key] ??
      symptom
          .split('_')
          .where((p) => p.isNotEmpty)
          .map((p) => '${p[0].toUpperCase()}${p.substring(1)}')
          .join(' ');
}

String _formatPtDateTime(DateTime dt) {
  const months = [
    'jan',
    'fev',
    'mar',
    'abr',
    'mai',
    'jun',
    'jul',
    'ago',
    'set',
    'out',
    'nov',
    'dez',
  ];
  final h = dt.hour.toString().padLeft(2, '0');
  final m = dt.minute.toString().padLeft(2, '0');
  return '${dt.day} ${months[dt.month - 1]} · $h:$m';
}

class SymptomSectionCard extends StatelessWidget {
  const SymptomSectionCard({super.key, required this.child, this.color});

  final Widget child;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BrutalDecor.box(color: color),
      child: child,
    );
  }
}

class SymptomFormBanner extends StatelessWidget {
  const SymptomFormBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.errorBgLight,
        border: Border.all(color: AppColors.dangerRed, width: 2),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: AppColors.dangerRed, offset: Offset(3, 3)),
        ],
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: AppColors.errorTextDark,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class SymptomSearchCard extends StatelessWidget {
  const SymptomSearchCard({
    super.key,
    required this.filteredSymptoms,
    required this.selectedSymptom,
    required this.searchController,
    required this.isLoading,
    required this.onSearchChanged,
    required this.onSymptomSelected,
  });

  final List<String> filteredSymptoms;
  final String? selectedSymptom;
  final TextEditingController searchController;
  final bool isLoading;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onSymptomSelected;

  @override
  Widget build(BuildContext context) {
    return SymptomSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Como te sentes?',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            style: const TextStyle(color: AppColors.ink),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search, color: AppColors.ink, size: 20),
              hintText: 'Pesquisar sintomas',
              hintStyle: TextStyle(color: AppColors.muted),
              filled: true,
              fillColor: AppColors.paper,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(10)),
                borderSide: BorderSide(color: AppColors.ink, width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(10)),
                borderSide: BorderSide(color: AppColors.ink, width: 2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(10)),
                borderSide: BorderSide(color: AppColors.lemon, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final symptom in filteredSymptoms)
                _SymptomChip(
                  label: _ptLabel(symptom),
                  isSelected: selectedSymptom == symptom,
                  isDisabled: isLoading,
                  onTap: () => onSymptomSelected(symptom),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SymptomChip extends StatelessWidget {
  const _SymptomChip({
    required this.label,
    required this.isSelected,
    required this.isDisabled,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.lemon : AppColors.card,
          border: BrutalDecor.border,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected ? BrutalDecor.shadowSm : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.ink,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class SeverityCard extends StatelessWidget {
  const SeverityCard({
    super.key,
    required this.severity,
    required this.severityColor,
    required this.isLoading,
    required this.onChanged,
  });

  final int severity;
  final Color severityColor;
  final bool isLoading;
  final ValueChanged<double>? onChanged;

  @override
  Widget build(BuildContext context) {
    return SymptomSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gravidade $severity/10',
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Indica a intensidade do sintoma agora.',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: severityColor,
              inactiveTrackColor: severityColor.withValues(alpha: 0.18),
              thumbColor: severityColor,
              overlayColor: severityColor.withValues(alpha: 0.12),
            ),
            child: Slider(
              value: severity.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              label: '$severity',
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class DateTimeCard extends StatelessWidget {
  const DateTimeCard({
    super.key,
    required this.occurredAt,
    required this.isLoading,
    required this.onPick,
  });

  final DateTime occurredAt;
  final bool isLoading;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return SymptomSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quando aconteceu?',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: isLoading ? null : onPick,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BrutalDecor.box(
                color: AppColors.paper,
                shadow: false,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.schedule, size: 18, color: AppColors.ink),
                  const SizedBox(width: 8),
                  Text(
                    _formatPtDateTime(occurredAt),
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class NotesCard extends StatelessWidget {
  const NotesCard({
    super.key,
    required this.notesController,
    required this.isLoading,
    required this.onChanged,
  });

  final TextEditingController notesController;
  final bool isLoading;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SymptomSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Notas adicionais',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: notesController,
            minLines: 3,
            maxLines: 5,
            onChanged: onChanged,
            style: const TextStyle(color: AppColors.ink),
            decoration: const InputDecoration(
              hintText: 'Descreve os fatores que podem ter contribuído.',
              hintStyle: TextStyle(color: AppColors.muted, fontSize: 13),
              filled: true,
              fillColor: AppColors.paper,
              contentPadding: EdgeInsets.all(14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(10)),
                borderSide: BorderSide(color: AppColors.ink, width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(10)),
                borderSide: BorderSide(color: AppColors.ink, width: 2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(10)),
                borderSide: BorderSide(color: AppColors.lemon, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
