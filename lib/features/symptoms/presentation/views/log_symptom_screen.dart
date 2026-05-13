import 'package:clinic_go/core/themes/app_colors.dart';
import 'package:clinic_go/features/symptoms/presentation/view_models/symptom_form_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class LogSymptomScreen extends ConsumerStatefulWidget {
  const LogSymptomScreen({super.key});

  @override
  ConsumerState<LogSymptomScreen> createState() => _LogSymptomScreenState();
}

class _LogSymptomScreenState extends ConsumerState<LogSymptomScreen> {
  late final TextEditingController _notesController;
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    final state = ref.read(symptomFormControllerProvider);
    _notesController = TextEditingController(text: state.notes);
    _searchController = TextEditingController(text: state.searchQuery);
  }

  @override
  void dispose() {
    _notesController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(symptomFormControllerProvider, (previous, next) {
      if (_notesController.text != next.notes) {
        _notesController.value = TextEditingValue(
          text: next.notes,
          selection: TextSelection.collapsed(offset: next.notes.length),
        );
      }

      if (_searchController.text != next.searchQuery) {
        _searchController.value = TextEditingValue(
          text: next.searchQuery,
          selection: TextSelection.collapsed(offset: next.searchQuery.length),
        );
      }
    });

    final state = ref.watch(symptomFormControllerProvider);
    final controller = ref.read(symptomFormControllerProvider.notifier);
    final severityColor = AppColors.severityColor(state.severity);

    return PopScope(
      canPop: !state.isDirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop || !state.isDirty) {
          return;
        }

        final shouldDiscard = await _confirmDiscardChanges(context);
        if (shouldDiscard && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F6F3),
        appBar: AppBar(
          title: const Text('Log Symptom'),
          backgroundColor: Colors.transparent,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (state.errorMessage != null) ...[
                  _FormBanner(message: state.errorMessage!),
                  const SizedBox(height: 16),
                ],
                _SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'How are you feeling?',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _searchController,
                        onChanged: controller.setSearchQuery,
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
                          for (final symptom in controller.filteredSymptoms)
                            ChoiceChip(
                              label: Text(_formatSymptom(symptom)),
                              selected: state.selectedSymptom == symptom,
                              onSelected: state.isLoading
                                  ? null
                                  : (_) => controller.selectSymptom(symptom),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Severity ${state.severity}/10',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Move the slider to show how intense the symptom feels right now.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.muted,
                        ),
                      ),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: severityColor,
                          inactiveTrackColor: severityColor.withValues(
                            alpha: 0.18,
                          ),
                          thumbColor: severityColor,
                          overlayColor: severityColor.withValues(alpha: 0.12),
                        ),
                        child: Slider(
                          value: state.severity.toDouble(),
                          min: 1,
                          max: 10,
                          divisions: 9,
                          label: '${state.severity}',
                          onChanged: state.isLoading
                              ? null
                              : controller.setSeverity,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'When did it happen?',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: state.isLoading
                            ? null
                            : () => _pickOccurredAt(
                                context,
                                controller,
                                state.occurredAt,
                              ),
                        icon: const Icon(Icons.schedule),
                        label: Text(
                          DateFormat(
                            'EEE, MMM d - h:mm a',
                          ).format(state.occurredAt),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Additional notes',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _notesController,
                        minLines: 4,
                        maxLines: 6,
                        onChanged: controller.setNotes,
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
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: state.isLoading
                        ? null
                        : () => _submit(context, ref),
                    style: FilledButton.styleFrom(
                      backgroundColor: severityColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: state.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Save symptom'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickOccurredAt(
    BuildContext context,
    SymptomFormController controller,
    DateTime current,
  ) async {
    final date = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );

    if (date == null) return;
    if (!context.mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );

    if (time == null) {
      return;
    }

    controller.setOccurredAt(
      DateTime(date.year, date.month, date.day, time.hour, time.minute),
    );
  }

  Future<void> _submit(BuildContext context, WidgetRef ref) async {
    final controller = ref.read(symptomFormControllerProvider.notifier);
    final success = await controller.submitSymptomLog();
    final state = ref.read(symptomFormControllerProvider);

    if (!context.mounted) {
      return;
    }

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Symptom saved successfully.')),
      );
      Navigator.of(context).pop();
      return;
    }

    if (state.errorMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
    }
  }

  Future<bool> _confirmDiscardChanges(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Discard changes?'),
            content: const Text(
              'You have unsaved symptom details. If you go back now, they will be lost.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Keep editing'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Discard'),
              ),
            ],
          ),
        ) ??
        false;
  }

  String _formatSymptom(String symptom) {
    return symptom
        .split('_')
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

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

class _FormBanner extends StatelessWidget {
  const _FormBanner({required this.message});

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
