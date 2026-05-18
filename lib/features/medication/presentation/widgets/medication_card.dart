import 'package:flutter/material.dart';
import 'package:clinic_go/core/themes/app_colors.dart';
import 'package:clinic_go/features/medication/models/medication.dart';
import 'package:clinic_go/features/medication/presentation/views/edit_medication_screen.dart';

typedef MedicationDeleteCallback = Future<void> Function(String id);

class MedicationCard extends StatefulWidget {
  const MedicationCard({
    super.key,
    required this.medication,
    required this.onEdited,
    required this.onDelete,
  });

  final Medication medication;
  final VoidCallback onEdited;
  final MedicationDeleteCallback onDelete;

  @override
  State<MedicationCard> createState() => _MedicationCardState();
}

class _MedicationCardState extends State<MedicationCard> {
  bool _expanded = false;
  bool _isDeleting = false;

  Future<void> _openEdit() async {
    final edited = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EditMedicationScreen(medication: widget.medication),
      ),
    );
    if (edited == true) {
      setState(() => _expanded = false);
      widget.onEdited();
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) =>
          _DeleteMedicationDialog(medicationName: widget.medication.name),
    );
    if (confirmed != true) return;

    setState(() => _isDeleting = true);
    try {
      await widget.onDelete(widget.medication.id);
      if (mounted) setState(() => _expanded = false);
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  String _firstTime() {
    final reminders = widget.medication.reminders;
    if (reminders == null || reminders.isEmpty) return '--';
    final parts = reminders.first.reminderTime.split(':');
    return '${parts[0]}:${parts[1]}';
  }

  @override
  Widget build(BuildContext context) {
    final med = widget.medication;

    return Container(
      decoration: BrutalDecor.box(radius: 16),
      clipBehavior: Clip.hardEdge,
      child: LayoutBuilder(
        builder: (ctx, constraints) {
          final panelWidth = _expanded ? constraints.maxWidth : 90.0;

          return Stack(
            children: [
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                  width: panelWidth,
                  color: med.color,
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _expanded
                      ? Container(
                          key: const ValueKey(true),
                          color: Colors.white,
                          width: constraints.maxWidth,
                          child: _expandedView(med),
                        )
                      : SizedBox(
                          key: const ValueKey(false),
                          width: constraints.maxWidth,
                          child: _collapsedView(med),
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _collapsedView(Medication med) {
    final timeColor = med.color.computeLuminance() < 0.4
        ? Colors.white
        : AppColors.ink;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 90,
            child: Center(
              child: Text(
                _firstTime(),
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: timeColor,
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(14, 13, 8, 13),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    med.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.ink,
                    ),
                  ),
                  if (med.dosageDisplay != null || med.frequency != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      [
                        if (med.dosageDisplay != null) med.dosageDisplay!,
                        if (med.frequency != null) med.frequency!,
                      ].join(' · '),
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                  if (med.notes != null && med.notes!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      med.notes!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.muted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Center(
              child: _CardButton(
                label: 'INFO',
                onTap: () => setState(() => _expanded = true),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _expandedView(Medication med) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 16, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: med.color,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.ink, width: 1.5),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            med.name,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                        if (med.isActive) const _AtivoBadge(),
                      ],
                    ),
                    if (med.dosageDisplay != null || med.frequency != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        [
                          if (med.dosageDisplay != null) med.dosageDisplay!,
                          if (med.frequency != null) med.frequency!,
                        ].join(' · '),
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        _ExpandedSection(
          med: med,
          onEdit: _openEdit,
          onDelete: _isDeleting ? null : _confirmDelete,
          onClose: () => setState(() => _expanded = false),
          isDeleting: _isDeleting,
        ),
      ],
    );
  }
}

class _AtivoBadge extends StatelessWidget {
  const _AtivoBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.mint,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.ink, width: 1.5),
      ),
      child: const Text(
        'ATIVO',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: AppColors.ink,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _ExpandedSection extends StatelessWidget {
  const _ExpandedSection({
    required this.med,
    required this.onEdit,
    required this.onDelete,
    required this.onClose,
    required this.isDeleting,
  });

  final Medication med;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;
  final VoidCallback onClose;
  final bool isDeleting;

  @override
  Widget build(BuildContext context) {
    final reminders = med.reminders ?? [];

    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.ink, width: 1.5)),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...reminders.asMap().entries.map((entry) {
                final parts = entry.value.reminderTime.split(':');
                final time = TimeOfDay(
                  hour: int.parse(parts[0]),
                  minute: int.parse(parts[1]),
                );
                final label = reminders.length > 1
                    ? 'HORÁRIO ${entry.key + 1}'
                    : 'HORÁRIO';
                return _InfoChip(label: label, value: time.format(context));
              }),
              _InfoChip(
                label: 'COM COMIDA',
                value: med.withFood ? 'Sim' : 'Não',
              ),
              if (med.notes != null && med.notes!.isNotEmpty)
                _InfoChip(label: 'NOTAS', value: med.notes!),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _CardButton(
                label: 'FECHAR',
                onTap: onClose,
                variant: _CardButtonVariant.secondary,
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _CardButton(
                        label: isDeleting ? 'A APAGAR...' : 'ELIMINAR',
                        onTap: onDelete,
                        variant: _CardButtonVariant.danger,
                      ),
                      _CardButton(label: 'EDITAR', onTap: onEdit),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.sky,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.ink, width: 1.5),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 12, color: AppColors.ink),
          children: [
            TextSpan(
              text: '$label  ',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}

class _DeleteMedicationDialog extends StatelessWidget {
  const _DeleteMedicationDialog({required this.medicationName});

  final String medicationName;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      elevation: 0,
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        decoration: BrutalDecor.box(color: AppColors.paper, radius: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE53935),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.ink, width: 1.5),
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Eliminar medicamento?',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Queres eliminar $medicationName? Esta ação não pode ser desfeita.',
              style: const TextStyle(
                fontSize: 14,
                height: 1.35,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 18),
            Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: [
                  _CardButton(
                    label: 'CANCELAR',
                    onTap: () => Navigator.of(context).pop(false),
                    variant: _CardButtonVariant.secondary,
                  ),
                  _CardButton(
                    label: 'ELIMINAR',
                    onTap: () => Navigator.of(context).pop(true),
                    variant: _CardButtonVariant.danger,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _CardButtonVariant { primary, secondary, danger }

class _CardButton extends StatelessWidget {
  const _CardButton({
    required this.label,
    required this.onTap,
    this.variant = _CardButtonVariant.primary,
  });

  final String label;
  final VoidCallback? onTap;
  final _CardButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final backgroundColor = switch (variant) {
      _CardButtonVariant.primary => AppColors.lemon,
      _CardButtonVariant.secondary => Colors.white,
      _CardButtonVariant.danger => const Color(0xFFE53935),
    };
    final foregroundColor = switch (variant) {
      _CardButtonVariant.secondary => AppColors.ink,
      _ => Colors.white,
    };

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: enabled
              ? backgroundColor
              : backgroundColor.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.ink, width: 1.5),
          boxShadow: BrutalDecor.shadowSm,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: foregroundColor,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
