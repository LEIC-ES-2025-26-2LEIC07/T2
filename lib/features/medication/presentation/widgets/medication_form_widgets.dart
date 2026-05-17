import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:clinic_go/features/medication/presentation/view_models/add_medication_view_model.dart';

// ── Shared design tokens ───────────────────────────────────────
const medInk = Color(0xFF0E2748);
const medPaper = Color(0xFFEEF3FA);
const medCard = Color(0xFFFFFFFF);
const medBlue = Color(0xFF3D6BE0);
const medMuted = Color(0xFF7A8AA5);
const medShadowSm = BoxShadow(
  color: medInk,
  offset: Offset(3, 3),
  blurRadius: 0,
);

const medQuickPalette = [
  Color(0xFFE0796A),
  Color(0xFF3D6BE0),
  Color(0xFFB7D8C7),
  Color(0xFFC9DCF7),
  Color(0xFFF4D6D2),
];

// ── Topo background ────────────────────────────────────────────

class MedTopoPainter extends CustomPainter {
  const MedTopoPainter();

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
  bool shouldRepaint(MedTopoPainter old) => false;
}

// ── Field widgets ──────────────────────────────────────────────

class MedLabeledField extends StatelessWidget {
  const MedLabeledField({
    super.key,
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
            color: medInk.withValues(alpha: 0.6),
            height: 1,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: medCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: medInk, width: 2),
            boxShadow: const [medShadowSm],
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

class MedPlainTextField extends StatelessWidget {
  const MedPlainTextField({
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
        color: medInk,
      ),
      decoration: InputDecoration(
        hintText: placeholder,
        hintStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: medMuted,
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

class MedDosageContent extends StatelessWidget {
  const MedDosageContent({
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
              color: medInk,
            ),
            decoration: InputDecoration(
              hintText: 'ex: 500',
              hintStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: medMuted,
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
        Container(width: 1, height: 28, color: medInk.withValues(alpha: 0.2)),
        DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: selectedUnit,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: medInk,
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

class MedTimeContent extends StatelessWidget {
  const MedTimeContent({super.key, required this.time, required this.onTap});

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
                color: medInk,
              ),
            ),
            const Icon(Icons.access_time_rounded, size: 18, color: medInk),
          ],
        ),
      ),
    );
  }
}

class MedFreqContent extends StatelessWidget {
  const MedFreqContent({
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
          color: medInk,
        ),
        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: medInk),
        items: options
            .map((o) => DropdownMenuItem(value: o, child: Text(o)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}

class MedFoodSwitchContent extends StatelessWidget {
  const MedFoodSwitchContent({
    super.key,
    required this.value,
    required this.onChanged,
  });

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
              color: medInk,
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: medBlue,
            activeThumbColor: medCard,
            inactiveThumbColor: medMuted,
            inactiveTrackColor: const Color(0xFFE0E7F0),
          ),
        ],
      ),
    );
  }
}

// ── Color section ─────────────────────────────────────────────

class MedColorSection extends StatelessWidget {
  const MedColorSection({
    super.key,
    required this.selectedColor,
    required this.onColorChanged,
    required this.onPickerTap,
    this.swatchKey,
  });

  final Color selectedColor;
  final ValueChanged<Color> onColorChanged;
  final VoidCallback onPickerTap;
  final Key? swatchKey;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GestureDetector(
          key: swatchKey,
          onTap: onPickerTap,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: selectedColor,
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
                final isSelected = selectedColor == c;
                return GestureDetector(
                  onTap: () => onColorChanged(c),
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
}

// ── Form bottom bar ────────────────────────────────────────────

class MedFormBottomBar extends StatelessWidget {
  const MedFormBottomBar({
    super.key,
    required this.isLoading,
    required this.onCancel,
    required this.onSave,
    required this.saveLabel,
    this.isSaveDisabled = false,
    this.saveButtonKey,
  });

  final bool isLoading;
  final Future<void> Function() onCancel;
  final VoidCallback onSave;
  final String saveLabel;
  final bool isSaveDisabled;
  final Key? saveButtonKey;

  @override
  Widget build(BuildContext context) {
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
                onPressed: isLoading
                    ? null
                    : () {
                        onCancel();
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
                key: saveButtonKey,
                onPressed: (isLoading || isSaveDisabled) ? null : onSave,
                style: FilledButton.styleFrom(
                  backgroundColor: medBlue,
                  disabledBackgroundColor: medBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        saveLabel,
                        style: const TextStyle(
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

// ── Color picker sheet ─────────────────────────────────────────

class MedColorPickerSheet extends StatelessWidget {
  const MedColorPickerSheet({
    super.key,
    required this.selected,
    required this.onSelected,
    this.title = 'Escolhe uma cor',
  });

  final Color selected;
  final ValueChanged<Color> onSelected;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                            ? Border.all(color: medInk, width: 3)
                            : Border.all(color: medInk, width: 1.5),
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
