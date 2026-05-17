import 'package:flutter/material.dart';
import 'package:clinic_go/core/themes/app_colors.dart';
import 'package:intl/intl.dart';

String formatSymptomLabel(String symptom) {
  return symptom
      .split('_')
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

class SymptomSectionCard extends StatelessWidget {
  const SymptomSectionCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F0),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFCDC7)),
      ),
      child: Text(message, style: const TextStyle(color: Color(0xFF9F3428))),
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
          Text(
            'How are you feeling?',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'Search symptoms',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final symptom in filteredSymptoms)
                ChoiceChip(
                  label: Text(formatSymptomLabel(symptom)),
                  selected: selectedSymptom == symptom,
                  onSelected: isLoading
                      ? null
                      : (_) => onSymptomSelected(symptom),
                ),
            ],
          ),
        ],
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
            'Severity $severity/10',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Move the slider to show how intense the symptom feels right now.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
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
          Text(
            'When did it happen?',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: isLoading ? null : onPick,
            icon: const Icon(Icons.schedule),
            label: Text(DateFormat('EEE, MMM d - h:mm a').format(occurredAt)),
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
          Text(
            'Additional notes',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: notesController,
            minLines: 4,
            maxLines: 6,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText:
                  'Add context like triggers, timing, or anything that changed.',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
