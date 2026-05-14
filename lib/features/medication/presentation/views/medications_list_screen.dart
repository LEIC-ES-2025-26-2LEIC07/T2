import 'package:flutter/material.dart';
import 'package:clinic_go/core/di/service_locator.dart';
import 'package:clinic_go/core/themes/app_colors.dart';
import 'package:clinic_go/core/widgets/clinic_go_logo.dart';
import 'package:clinic_go/features/medication/data/medication_repository.dart';
import 'package:clinic_go/features/medication/models/medication.dart';
import 'package:clinic_go/features/medication/presentation/view_models/medications_list_view_model.dart';
import 'package:clinic_go/features/medication/presentation/views/add_medication_screen.dart';
import 'package:clinic_go/features/medication/presentation/views/edit_medication_screen.dart';

/// Medication list embedded in the main shell at nav-bar index 1.
class MedicationsListScreen extends StatefulWidget {
  const MedicationsListScreen({super.key, this.onChanged});

  /// Called after a medication is added, edited, or deleted.
  final VoidCallback? onChanged;

  @override
  State<MedicationsListScreen> createState() => _MedicationsListScreenState();
}

class _MedicationsListScreenState extends State<MedicationsListScreen> {
  late final MedicationsListViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = MedicationsListViewModel(
      repository: getIt<MedicationRepository>(),
    );
    _viewModel.loadMedications();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _openAddMedication() async {
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AddMedicationScreen()),
    );
    if (added == true) {
      await _viewModel.loadMedications();
      widget.onChanged?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 90),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Logo row ────────────────────────────────────────
            const ClinicGoLogo(),
            const SizedBox(height: 12),

            // ── Title + add button ──────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Medicação',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                    letterSpacing: -0.5,
                  ),
                ),
                const Spacer(),
                _AddButton(onTap: _openAddMedication),
              ],
            ),
            const SizedBox(height: 20),

            // ── Medication cards ────────────────────────────────
            Expanded(
              child: AnimatedBuilder(
                animation: _viewModel,
                builder: (context, _) {
                  if (_viewModel.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (_viewModel.errorMessage != null) {
                    return _ErrorState(
                      message: _viewModel.errorMessage!,
                      onRetry: _viewModel.loadMedications,
                    );
                  }
                  if (_viewModel.medications.isEmpty) {
                    return _EmptyState(onAdd: _openAddMedication);
                  }
                  return ListView.separated(
                    itemCount: _viewModel.medications.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 16),
                    itemBuilder: (_, i) => _MedicationCard(
                      medication: _viewModel.medications[i],
                      onEdited: () {
                        _viewModel.loadMedications();
                        widget.onChanged?.call();
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header add button ───────────────────────────────────────────────

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BrutalDecor.box(color: AppColors.lemon, radius: 30),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, color: Colors.white, size: 18),
            SizedBox(width: 4),
            Text(
              'Adicionar',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty / Error states ────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.medication_outlined,
            size: 64,
            color: Color(0xFFB0B0B0),
          ),
          const SizedBox(height: 16),
          const Text(
            'Nenhum medicamento',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Toque em Adicionar para começar.',
            style: TextStyle(color: Colors.black38),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: onAdd,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BrutalDecor.box(color: AppColors.lemon, radius: 30),
              child: const Text(
                'Adicionar medicamento',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

// ── Medication card ─────────────────────────────────────────────────

class _MedicationCard extends StatefulWidget {
  const _MedicationCard({required this.medication, required this.onEdited});
  final Medication medication;
  final VoidCallback onEdited;

  @override
  State<_MedicationCard> createState() => _MedicationCardState();
}

class _MedicationCardState extends State<_MedicationCard> {
  bool _expanded = false;

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

  @override
  Widget build(BuildContext context) {
    final med = widget.medication;

    return Container(
      decoration: BrutalDecor.box(radius: 16),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Always-visible header ──────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 16, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Colour square
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
                // Name + dosage · frequency
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
                      if (med.dosage != null || med.frequency != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          [
                            if (med.dosage != null) med.dosage!,
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

          // VER INFO / ESCONDER INFO toggle
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 16, 10),
            child: Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _expanded ? 'ESCONDER INFO' : 'VER INFO',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: 18,
                      color: AppColors.ink,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Expanded section ───────────────────────────────
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            child: _expanded
                ? _ExpandedSection(med: med, onEdit: _openEdit)
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// ── ATIVO badge ─────────────────────────────────────────────────────

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

// ── Expanded section ────────────────────────────────────────────────

class _ExpandedSection extends StatelessWidget {
  const _ExpandedSection({required this.med, required this.onEdit});
  final Medication med;
  final VoidCallback onEdit;

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
            mainAxisAlignment: MainAxisAlignment.end,
            children: [_CardButton(label: 'EDITAR', onTap: onEdit)],
          ),
        ],
      ),
    );
  }
}

// ── Info chip ───────────────────────────────────────────────────────

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

// ── Card action button ──────────────────────────────────────────────

class _CardButton extends StatelessWidget {
  const _CardButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.lemon,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.ink, width: 1.5),
          boxShadow: BrutalDecor.shadowSm,
        ),
        child: const Text(
          'EDITAR',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
