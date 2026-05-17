import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:clinic_go/core/di/service_locator.dart';
import 'package:clinic_go/features/medication/data/medication_repository.dart';
import 'package:clinic_go/features/medication/models/medication.dart';
import 'package:clinic_go/features/medication/presentation/view_models/add_medication_view_model.dart';
import 'package:clinic_go/features/medication/presentation/view_models/edit_medication_view_model.dart';

// ── Design tokens ──────────────────────────────────────────────
const _ink = Color(0xFF0E2748);
const _paper = Color(0xFFEEF3FA);
const _card = Color(0xFFFFFFFF);
const _blue = Color(0xFF3D6BE0);
const _muted = Color(0xFF7A8AA5);
const _shadowSm = BoxShadow(color: _ink, offset: Offset(3, 3), blurRadius: 0);

const _quickPalette = [
  Color(0xFFE0796A),
  Color(0xFF3D6BE0),
  Color(0xFFB7D8C7),
  Color(0xFFC9DCF7),
  Color(0xFFF4D6D2),
];

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
      builder: (_) => _ColorPickerSheet(
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
        backgroundColor: _paper,
        body: SafeArea(
          child: AnimatedBuilder(
            animation: _viewModel,
            builder: (context, _) => Stack(
              fit: StackFit.expand,
              children: [
                const CustomPaint(painter: _TopoPainter()),
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
                _LabeledField(
                  label: 'Nome',
                  errorText: _viewModel.nameError,
                  child: _PlainTextField(
                    key: const Key('edit_med_name_field'),
                    controller: _nameController,
                    placeholder: 'ex: Metformina',
                    onChanged: _viewModel.setName,
                    textInputAction: TextInputAction.next,
                  ),
                ),
                const SizedBox(height: 12),
                _LabeledField(
                  label: 'Dosagem',
                  errorText: _viewModel.dosageError,
                  child: _DosageContent(
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
                      child: _LabeledField(
                        label: _viewModel.reminderSlots.length > 1
                            ? 'Horário (${i + 1})'
                            : 'Horário',
                        child: _TimeContent(
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
                        color: _ink.withValues(alpha: 0.65),
                      ),
                    ),
                  ),
                ],
                _LabeledField(
                  label: 'Frequência',
                  child: _FreqContent(
                    key: const Key('edit_med_freq_field'),
                    value: _viewModel.frequency,
                    options: AddMedicationViewModel.frequencyOptions,
                    onChanged: _viewModel.setFrequency,
                  ),
                ),
                const SizedBox(height: 12),
                _LabeledField(
                  label: 'Com comida',
                  child: _FoodSwitchContent(
                    value: _viewModel.withFood,
                    onChanged: _viewModel.setWithFood,
                  ),
                ),
                const SizedBox(height: 12),
                _LabeledField(
                  label: 'Notas (opcional)',
                  child: _PlainTextField(
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
                      border: Border.all(color: _ink, width: 2),
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
                color: _card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _ink, width: 2),
                boxShadow: const [_shadowSm],
              ),
              child: const Icon(Icons.arrow_back, size: 18, color: _ink),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Editar medicação',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: _ink,
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
              border: Border.all(color: _ink, width: 2.5),
              boxShadow: const [_shadowSm],
            ),
            child: Align(
              alignment: Alignment.bottomRight,
              child: Transform.translate(
                offset: const Offset(6, 6),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: _card,
                    shape: BoxShape.circle,
                    border: Border.all(color: _ink, width: 2),
                  ),
                  child: const Icon(Icons.edit, size: 11, color: _ink),
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
                color: _ink.withValues(alpha: 0.6),
                height: 1,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Toca para mudar',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _ink,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: _quickPalette.map((c) {
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
                        color: _ink,
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
        color: _card,
        border: Border(top: BorderSide(color: _ink, width: 2)),
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
                  backgroundColor: _paper,
                  foregroundColor: _ink,
                  side: const BorderSide(color: _ink, width: 2),
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
                  backgroundColor: _blue,
                  disabledBackgroundColor: _blue,
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

// ── Topo background ────────────────────────────────────────────

class _TopoPainter extends CustomPainter {
  const _TopoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x260E2748)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7;

    final sx = size.width / 390;
    final sy = size.height / 800;

    _drawGroup(canvas, paint, 180, 200, 9, 32, 30, 0.9, sx, sy);
    _drawGroup(canvas, paint, 310, 660, 10, 30, 22, 1.1, sx, sy);
    _drawGroup(canvas, paint, 50, 380, 8, 30, 26, 1.0, sx, sy);
  }

  void _drawGroup(
    Canvas canvas,
    Paint paint,
    double cx,
    double cy,
    int count,
    double base,
    double step,
    double ar,
    double sx,
    double sy,
  ) {
    for (int i = 0; i < count; i++) {
      final ry = base + i * step;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx * sx, cy * sy),
          width: ry * ar * 2 * sx,
          height: ry * 2 * sy,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_TopoPainter old) => false;
}

// ── Field widgets ──────────────────────────────────────────────

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.child,
    this.errorText,
  });

  final String label;
  final Widget child;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
            color: _ink.withValues(alpha: 0.6),
            height: 1,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _ink, width: 2),
            boxShadow: const [_shadowSm],
          ),
          child: child,
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 4),
            child: Text(
              errorText!,
              style: const TextStyle(color: Color(0xFFC62828), fontSize: 12),
            ),
          ),
      ],
    );
  }
}

class _PlainTextField extends StatelessWidget {
  const _PlainTextField({
    super.key,
    required this.controller,
    required this.placeholder,
    this.onChanged,
    this.textInputAction,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String placeholder;
  final ValueChanged<String>? onChanged;
  final TextInputAction? textInputAction;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: textInputAction,
      maxLines: maxLines,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: _ink,
      ),
      decoration: InputDecoration(
        hintText: placeholder,
        hintStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: _muted,
        ),
        filled: false,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
      ),
    );
  }
}

class _DosageContent extends StatelessWidget {
  const _DosageContent({
    super.key,
    required this.controller,
    required this.selectedUnit,
    required this.units,
    required this.onAmountChanged,
    required this.onUnitChanged,
  });

  final TextEditingController controller;
  final String selectedUnit;
  final List<String> units;
  final ValueChanged<String> onAmountChanged;
  final ValueChanged<String?> onUnitChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            onChanged: onAmountChanged,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textInputAction: TextInputAction.next,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _ink,
            ),
            decoration: InputDecoration(
              hintText: 'ex: 500',
              hintStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _muted,
              ),
              filled: false,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
          ),
        ),
        Container(width: 1, height: 28, color: _ink.withValues(alpha: 0.2)),
        DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: selectedUnit,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: _ink,
            ),
            items: units
                .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                .toList(),
            onChanged: onUnitChanged,
          ),
        ),
      ],
    );
  }
}

class _TimeContent extends StatelessWidget {
  const _TimeContent({super.key, required this.time, required this.onTap});

  final TimeOfDay time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              time.format(context),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _ink,
              ),
            ),
            const Icon(Icons.access_time_rounded, size: 18, color: _ink),
          ],
        ),
      ),
    );
  }
}

class _FreqContent extends StatelessWidget {
  const _FreqContent({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String value;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: _ink,
        ),
        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _ink),
        items: options
            .map((o) => DropdownMenuItem(value: o, child: Text(o)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}

class _FoodSwitchContent extends StatelessWidget {
  const _FoodSwitchContent({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            value ? 'Sim' : 'Não',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _ink,
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: _blue,
            activeThumbColor: _card,
            inactiveThumbColor: _muted,
            inactiveTrackColor: const Color(0xFFE0E7F0),
          ),
        ],
      ),
    );
  }
}

// ── Color picker sheet ─────────────────────────────────────────

class _ColorPickerSheet extends StatelessWidget {
  const _ColorPickerSheet({required this.selected, required this.onSelected});

  final Color selected;
  final ValueChanged<Color> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Escolhe uma cor',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: AddMedicationViewModel.colorPalette
                .map(
                  (c) => GestureDetector(
                    onTap: () => onSelected(c),
                    child: Container(
                      key: Key('color_${c.toARGB32().toRadixString(16)}'),
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: c == selected
                            ? Border.all(color: _ink, width: 3)
                            : Border.all(color: _ink, width: 1.5),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}
