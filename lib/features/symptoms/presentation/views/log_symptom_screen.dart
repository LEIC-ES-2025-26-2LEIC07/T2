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
        backgroundColor: AppColors.paper,
        body: DecoratedBox(
          decoration: const BoxDecoration(
            color: AppColors.paper,
            image: DecorationImage(
              image: AssetImage('assets/images/wallpaper-sky.png'),
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                const _LogSymptomHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
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
                          onChanged: state.isLoading
                              ? null
                              : controller.setSeverity,
                        ),
                        const SizedBox(height: 16),
                        DateTimeCard(
                          occurredAt: state.occurredAt,
                          isLoading: state.isLoading,
                          onPick: () => _pickOccurredAt(
                            context,
                            controller,
                            state.occurredAt,
                          ),
                        ),
                        const SizedBox(height: 16),
                        NotesCard(
                          notesController: _notesController,
                          isLoading: state.isLoading,
                          onChanged: controller.setNotes,
                        ),
                        const SizedBox(height: 28),
                        _SubmitButton(
                          isLoading: state.isLoading,
                          onPressed: state.isLoading
                              ? null
                              : () => _submit(context, ref),
                        ),
                      ],
                    ),
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
        const SnackBar(content: Text('Sintoma guardado com sucesso.')),
      );
      Navigator.of(context).pop();
    }
  }

  Future<bool> _confirmDiscardChanges(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Descartar alterações?'),
            content: const Text(
              'Tens dados não guardados. Se saires agora, serão perdidos.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Continuar a editar'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Descartar'),
              ),
            ],
          ),
        ) ??
        false;
  }
}

class _LogSymptomHeader extends StatelessWidget {
  const _LogSymptomHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 14, 24, 0),
      child: Row(
        children: [
          SizedBox(
            width: 38,
            height: 38,
            child: IconButton(
              padding: EdgeInsets.zero,
              onPressed: () => Navigator.of(context).maybePop(),
              style: IconButton.styleFrom(
                backgroundColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  side: const BorderSide(color: AppColors.ink, width: 2),
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
              icon: const Icon(
                Icons.chevron_left,
                color: AppColors.ink,
                size: 30,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Registar sintoma',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({required this.isLoading, required this.onPressed});

  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: onPressed == null ? AppColors.muted : AppColors.lemon,
          border: BrutalDecor.border,
          borderRadius: BorderRadius.circular(14),
          boxShadow: onPressed == null ? null : BrutalDecor.shadow,
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  'Guardar sintoma',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
        ),
      ),
    );
  }
}
