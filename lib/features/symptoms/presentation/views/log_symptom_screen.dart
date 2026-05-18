import 'package:clinic_go/core/themes/app_colors.dart';
import 'package:clinic_go/features/symptoms/presentation/view_models/symptom_form_controller.dart';
import 'package:clinic_go/features/symptoms/presentation/widgets/symptom_form_sections.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
        if (didPop || !state.isDirty) return;
        final shouldDiscard = await _confirmDiscardChanges(context);
        if (shouldDiscard && context.mounted) Navigator.of(context).pop();
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
                  SymptomFormBanner(message: state.errorMessage!),
                  const SizedBox(height: 16),
                ],
                SymptomSearchCard(
                  filteredSymptoms: controller.filteredSymptoms,
                  selectedSymptom: state.selectedSymptom,
                  searchController: _searchController,
                  isLoading: state.isLoading,
                  onSearchChanged: controller.setSearchQuery,
                  onSymptomSelected: controller.selectSymptom,
                ),
                const SizedBox(height: 16),
                SeverityCard(
                  severity: state.severity,
                  severityColor: severityColor,
                  isLoading: state.isLoading,
                  onChanged: state.isLoading ? null : controller.setSeverity,
                ),
                const SizedBox(height: 16),
                DateTimeCard(
                  occurredAt: state.occurredAt,
                  isLoading: state.isLoading,
                  onPick: () =>
                      _pickOccurredAt(context, controller, state.occurredAt),
                ),
                const SizedBox(height: 16),
                NotesCard(
                  notesController: _notesController,
                  isLoading: state.isLoading,
                  onChanged: controller.setNotes,
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
                              color: AppColors.card,
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
    if (time == null) return;

    controller.setOccurredAt(
      DateTime(date.year, date.month, date.day, time.hour, time.minute),
    );
  }

  Future<void> _submit(BuildContext context, WidgetRef ref) async {
    final controller = ref.read(symptomFormControllerProvider.notifier);
    final success = await controller.submitSymptomLog();
    if (!context.mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Symptom saved successfully.')),
      );
      Navigator.of(context).pop();
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
}
