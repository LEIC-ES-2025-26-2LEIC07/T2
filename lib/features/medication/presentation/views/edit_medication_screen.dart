import 'package:flutter/material.dart';
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
        title: const Text('Descartar alterações?'),
        content: const Text('As alterações não guardadas serão perdidas.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Continuar a editar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Descartar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    return result ?? false;
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
                _buildColorSection(),
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
                  child: MedFreqContent(
                    key: const Key('edit_med_freq_field'),
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
        _buildBottomBar(context),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () async {
              final navigator = Navigator.of(context);
              if (await _confirmDiscard() && mounted) {
                navigator.pop(false);
              }
            },
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

  Widget _buildColorSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GestureDetector(
          key: const Key('edit_med_color_swatch'),
          onTap: _pickColor,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: _viewModel.selectedColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: medInk, width: 2.5),
              boxShadow: const [medShadowSm],
            ),
            child: Align(
              alignment: Alignment.bottomRight,
              child: Transform.translate(
                offset: const Offset(6, 6),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: medCard,
                    shape: BoxShape.circle,
                    border: Border.all(color: medInk, width: 2),
                  ),
                  child: const Icon(Icons.edit, size: 11, color: medInk),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'COR',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
                color: medInk.withValues(alpha: 0.6),
                height: 1,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Toca para mudar',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: medInk,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: medQuickPalette.map((c) {
                final isSelected = _viewModel.selectedColor == c;
                return GestureDetector(
                  onTap: () => _viewModel.setColor(c),
                  child: Container(
                    width: 22,
                    height: 22,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: c,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: medInk,
                        width: isSelected ? 2.5 : 1.5,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: medCard,
        border: Border(top: BorderSide(color: medInk, width: 2)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 52,
              child: OutlinedButton(
                onPressed: _viewModel.isLoading
                    ? null
                    : () async {
                        final navigator = Navigator.of(context);
                        if (await _confirmDiscard() && mounted) {
                          navigator.pop(false);
                        }
                      },
                style: OutlinedButton.styleFrom(
                  backgroundColor: medPaper,
                  foregroundColor: medInk,
                  side: const BorderSide(color: medInk, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 52,
              child: FilledButton(
                key: const Key('edit_med_save_button'),
                onPressed:
                    (_viewModel.isLoading || _viewModel.isLoadingReminders)
                    ? null
                    : _viewModel.submit,
                style: FilledButton.styleFrom(
                  backgroundColor: medBlue,
                  disabledBackgroundColor: medBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: _viewModel.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Guardar alterações',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
