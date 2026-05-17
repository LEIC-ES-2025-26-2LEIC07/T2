import 'package:flutter/material.dart';
import 'package:clinic_go/core/di/service_locator.dart';
import 'package:clinic_go/features/medication/data/medication_repository.dart';
import 'package:clinic_go/features/medication/presentation/view_models/add_medication_view_model.dart';
import 'package:clinic_go/features/medication/presentation/widgets/medication_form_widgets.dart';
import 'package:clinic_go/features/medication/services/missed_dose_notification_controller.dart';
import 'package:clinic_go/features/medication/services/dose_scheduling_service.dart';

class AddMedicationScreen extends StatefulWidget {
  const AddMedicationScreen({super.key});

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  late final AddMedicationViewModel _viewModel;
  final _nameController = TextEditingController();
  final _dosageAmountController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _viewModel = AddMedicationViewModel(
      repository: getIt<MedicationRepository>(),
      notificationController: getIt<MissedDoseNotificationController>(),
      schedulingService: getIt<DoseSchedulingService>(),
    );
    _viewModel.addListener(_onViewModelChanged);
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
          content: Text('Medication saved successfully!'),
          backgroundColor: Color(0xFF43A047),
        ),
      );
      Navigator.of(context).pop(true);
    }
  }

  Future<bool> _confirmDiscard() async {
    if (!_viewModel.isDirty) return true;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('Your unsaved medication data will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep editing'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Discard', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

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
        title: 'Choose a colour',
        onSelected: (c) {
          _viewModel.setColor(c);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  Future<void> _pickReminderTime(int index) async {
    final current = _viewModel.reminderTimes[index];
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
                  swatchKey: const Key('med_color_swatch'),
                  selectedColor: _viewModel.selectedColor,
                  onColorChanged: _viewModel.setColor,
                  onPickerTap: _pickColor,
                ),
                const SizedBox(height: 20),
                MedLabeledField(
                  label: 'Nome',
                  errorText: _viewModel.nameError,
                  child: MedPlainTextField(
                    key: const Key('med_name_field'),
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
                    key: const Key('med_dosage_field'),
                    controller: _dosageAmountController,
                    selectedUnit: _viewModel.dosageUnit,
                    units: AddMedicationViewModel.dosageUnits,
                    onAmountChanged: (v) =>
                        _viewModel.setDosageAmount(int.tryParse(v)),
                    onUnitChanged: (u) => _viewModel.setDosageUnit(u ?? 'mg'),
                  ),
                ),
                const SizedBox(height: 12),
                ...List.generate(
                  _viewModel.reminderTimes.length,
                  (i) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: MedLabeledField(
                      label: _viewModel.reminderTimes.length > 1
                          ? 'Horário (${i + 1})'
                          : 'Horário',
                      child: MedTimeContent(
                        key: Key('med_time_$i'),
                        time: _viewModel.reminderTimes[i],
                        onTap: () => _pickReminderTime(i),
                      ),
                    ),
                  ),
                ),
                MedLabeledField(
                  label: 'Frequência',
                  child: MedFreqContent(
                    key: const Key('med_freq_field'),
                    value: _viewModel.frequency,
                    options: AddMedicationViewModel.frequencyOptions,
                    onChanged: _viewModel.setFrequency,
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
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFECEC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: medInk, width: 2),
                    ),
                    child: Text(
                      _viewModel.errorMessage!,
                      style: const TextStyle(
                        color: Color(0xFFC62828),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
        MedFormBottomBar(
          isLoading: _viewModel.isLoading,
          saveButtonKey: const Key('med_save_button'),
          saveLabel: 'Guardar',
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
          const Expanded(
            child: Text(
              'Adicionar medicação',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: medInk,
                letterSpacing: -0.5,
              ),
            ),
          ),
          GestureDetector(
            key: const Key('med_close_button'),
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
              child: const Icon(Icons.close, size: 18, color: medInk),
            ),
          ),
        ],
      ),
    );
  }
}
