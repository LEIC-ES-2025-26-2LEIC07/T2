import 'package:flutter/material.dart';
import 'package:clinic_go/core/themes/app_colors.dart';
import 'package:clinic_go/core/di/service_locator.dart';
import 'package:clinic_go/features/medication/data/medication_repository.dart';
import 'package:clinic_go/features/medication/models/medication.dart';
import 'package:clinic_go/features/medication/presentation/view_models/add_medication_view_model.dart';
import 'package:clinic_go/features/medication/presentation/view_models/edit_medication_view_model.dart';
import 'package:clinic_go/features/medication/presentation/widgets/medication_form_widgets.dart';

class EditMedicationScreen extends StatefulWidget {
  const EditMedicationScreen({super.key, required this.medication});

  final Medication medication;

  @override
  State<EditMedicationScreen> createState() => _EditMedicationScreenState();
}

class _EditMedicationScreenState extends State<EditMedicationScreen> {
  late final EditMedicationViewModel _viewModel;
  late final TextEditingController _nameController;
  late final TextEditingController _dosageAmountController;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _viewModel = EditMedicationViewModel(
      repository: getIt<MedicationRepository>(),
      medication: widget.medication,
    );
    _nameController = TextEditingController(text: widget.medication.name);
    _dosageAmountController = TextEditingController(
      text: widget.medication.dosageAmount?.toString() ?? '',
    );
    _notesController = TextEditingController(
      text: widget.medication.notes ?? '',
    );

    _viewModel.addListener(_onViewModelChanged);
    _viewModel.loadReminders();
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);
    _viewModel.dispose();
    _nameController.dispose();
    _dosageAmountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onViewModelChanged() {
    if (_viewModel.isSuccess && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Medicamento atualizado com sucesso!'),
          backgroundColor: AppColors.successGreen,
        ),
      );
      Navigator.of(context).pop(true);
    }
  }

  Future<bool> _confirmDiscard() => showDiscardChangesDialog(
    context,
    isDirty: _viewModel.isDirty,
    title: 'Descartar alterações?',
    content: 'As alterações não guardadas serão perdidas.',
    cancelLabel: 'Continuar a editar',
    discardLabel: 'Descartar',
  );

  Future<void> _cancelAndPop() async {
    final navigator = Navigator.of(context);
    if (await _confirmDiscard() && mounted) {
      navigator.pop(false);
    }
  }

  Future<void> _pickColor() async {
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => MedColorPickerSheet(
        selected: _viewModel.selectedColor,
        onSelected: (c) {
          _viewModel.setColor(c);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  Future<void> _pickReminderTime(int index) async {
    final current = _viewModel.reminderSlots[index].time;
    final picked = await showTimePicker(context: context, initialTime: current);
    if (picked != null) _viewModel.setReminderTime(index, picked);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmDiscard() && context.mounted) {
          Navigator.of(context).pop(false);
        }
      },
      child: Scaffold(
        backgroundColor: medPaper,
        body: SafeArea(
          child: AnimatedBuilder(
            animation: _viewModel,
            builder: (context, _) => Stack(
              fit: StackFit.expand,
              children: [
                const CustomPaint(painter: MedTopoPainter()),
                _buildContent(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      children: [
        _buildHeader(context),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MedColorSection(
                  swatchKey: const Key('edit_med_color_swatch'),
                  selectedColor: _viewModel.selectedColor,
                  onColorChanged: _viewModel.setColor,
                  onPickerTap: _pickColor,
                ),
                const SizedBox(height: 20),
                MedLabeledField(
                  label: 'Nome',
                  errorText: _viewModel.nameError,
                  child: MedPlainTextField(
                    key: const Key('edit_med_name_field'),
                    controller: _nameController,
                    placeholder: 'ex: Metformina',
                    onChanged: _viewModel.setName,
                    textInputAction: TextInputAction.next,
                  ),
                ),
                const SizedBox(height: 12),
                MedLabeledField(
                  label: 'Dosagem',
                  errorText: _viewModel.dosageError,
                  child: MedDosageContent(
                    key: const Key('edit_med_dosage_field'),
                    controller: _dosageAmountController,
                    selectedUnit: _viewModel.dosageUnit,
                    units: AddMedicationViewModel.dosageUnits,
                    onAmountChanged: (v) =>
                        _viewModel.setDosageAmount(int.tryParse(v)),
                    onUnitChanged: (u) => _viewModel.setDosageUnit(u ?? 'mg'),
                  ),
                ),
                const SizedBox(height: 12),
                if (_viewModel.isLoadingReminders)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else ...[
                  ...List.generate(
                    _viewModel.reminderSlots.length,
                    (i) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: MedLabeledField(
                        label: _viewModel.reminderSlots.length > 1
                            ? 'Horário (${i + 1})'
                            : 'Horário',
                        child: MedTimeContent(
                          key: Key('edit_med_time_$i'),
                          time: _viewModel.reminderSlots[i].time,
                          onTap: () => _pickReminderTime(i),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Alterar horários atualiza lembretes futuros, mas preserva o histórico passado.',
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: medInk.withValues(alpha: 0.65),
                      ),
                    ),
                  ),
                ],
                MedLabeledField(
                  label: 'Frequência',
                  child: MedIntervalContent(
                    key: const Key('edit_med_freq_field'),
                    intervalDays: _viewModel.intervalDays,
                    onChanged: _viewModel.setIntervalDays,
                  ),
                ),
                const SizedBox(height: 12),
                MedLabeledField(
                  label: 'Com comida',
                  child: MedFoodSwitchContent(
                    value: _viewModel.withFood,
                    onChanged: _viewModel.setWithFood,
                  ),
                ),
                const SizedBox(height: 12),
                MedLabeledField(
                  label: 'Notas (opcional)',
                  child: MedPlainTextField(
                    controller: _notesController,
                    placeholder: 'ex: com o pequeno-almoço',
                    onChanged: _viewModel.setNotes,
                    maxLines: 2,
                  ),
                ),
                if (_viewModel.errorMessage != null) ...[
                  const SizedBox(height: 12),
                  MedErrorBox(message: _viewModel.errorMessage!),
                ],
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
        MedFormBottomBar(
          isLoading: _viewModel.isLoading,
          isSaveDisabled: _viewModel.isLoadingReminders,
          saveButtonKey: const Key('edit_med_save_button'),
          saveLabel: 'Guardar alterações',
          onCancel: _cancelAndPop,
          onSave: _viewModel.submit,
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: _cancelAndPop,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: medCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: medInk, width: 2),
                boxShadow: const [medShadowSm],
              ),
              child: const Icon(Icons.arrow_back, size: 18, color: medInk),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Editar medicação',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: medInk,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
