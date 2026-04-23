import 'dart:io';

import 'package:flutter/material.dart';
import 'package:clinic_go/core/di/service_locator.dart';
import 'package:clinic_go/features/medication/data/dose_log_repository.dart';
import 'package:clinic_go/features/medication/data/medication_repository.dart';
import 'package:clinic_go/features/medication/models/medication.dart';
import 'package:clinic_go/features/medication/models/scheduled_dose.dart';
import 'package:clinic_go/features/medication/presentation/view_models/daily_doses_view_model.dart';
import 'package:clinic_go/features/medication/presentation/view_models/medications_list_view_model.dart';
import 'package:clinic_go/features/medication/presentation/views/add_medication_screen.dart';
import 'package:clinic_go/features/medication/services/dose_scheduling_service.dart';

/// Medication list embedded in the main shell at nav-bar index 1.
/// Displays coloured cards (colour = chosen colour from add form).
class MedicationsListScreen extends StatefulWidget {
  const MedicationsListScreen({super.key, this.dosesViewModel});

  /// Optional injection for widget tests; created internally when null.
  final DailyDosesViewModel? dosesViewModel;

  @override
  State<MedicationsListScreen> createState() => _MedicationsListScreenState();
}

class _MedicationsListScreenState extends State<MedicationsListScreen> {
  late final MedicationsListViewModel _viewModel;
  late final DailyDosesViewModel _dosesViewModel;
  bool _ownsDosesViewModel = false;

  @override
  void initState() {
    super.initState();
    _viewModel = MedicationsListViewModel(
      repository: getIt<MedicationRepository>(),
    );
    _viewModel.loadMedications();

    if (widget.dosesViewModel != null) {
      _dosesViewModel = widget.dosesViewModel!;
    } else {
      _dosesViewModel = DailyDosesViewModel(
        repository: getIt<MedicationRepository>(),
        schedulingService: getIt<DoseSchedulingService>(),
        logRepository: getIt<DoseLogRepository>(),
      );
      _ownsDosesViewModel = true;
    }
    _dosesViewModel.loadTodayDoses();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    if (_ownsDosesViewModel) _dosesViewModel.dispose();
    super.dispose();
  }

  Future<void> _openAddMedication() async {
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AddMedicationScreen()),
    );
    if (added == true) {
      await _viewModel.loadMedications();
      await _dosesViewModel.loadTodayDoses();
    }
  }

  Future<void> _logDose(ScheduledDose dose, DoseLogStatus status) async {
    try {
      await _dosesViewModel.logDose(dose: dose, status: status);
    } catch (e) {
      if (!mounted) return;
      final message = e is SocketException
          ? 'Network error. Please check your connection and try again.'
          : 'We could not save this dose right now. Please try again.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
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
            // ── Header ─────────────────────────────────────────
            Row(
              children: [
                const Text(
                  'Medication',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: _openAddMedication,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF4E84E5),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Add +',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Today's Doses ───────────────────────────────────
            AnimatedBuilder(
              animation: _dosesViewModel,
              builder: (context, _) => _TodaysDosesSection(
                doses: _dosesViewModel.doses,
                isLoading: _dosesViewModel.isLoading,
                onLog: _logDose,
              ),
            ),
            const SizedBox(height: 16),

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
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (_, i) =>
                        _MedicationCard(medication: _viewModel.medications[i]),
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

// ── Today's Doses section ───────────────────────────────────────────

class _TodaysDosesSection extends StatelessWidget {
  const _TodaysDosesSection({
    required this.doses,
    required this.isLoading,
    required this.onLog,
  });

  final List<DoseItem> doses;
  final bool isLoading;
  final Future<void> Function(ScheduledDose dose, DoseLogStatus status) onLog;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const Text(
              "Today's Doses",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            if (isLoading) ...[
              const SizedBox(width: 12),
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        if (!isLoading && doses.isEmpty)
          const Text(
            'No doses scheduled for today.',
            style: TextStyle(color: Colors.black45, fontSize: 14),
          )
        else
          ...doses.map(
            (item) => _DoseRow(
              item: item,
              onTake: () => onLog(item.dose, DoseLogStatus.taken),
              onSkip: () => onLog(item.dose, DoseLogStatus.skipped),
            ),
          ),
        const Divider(height: 24),
      ],
    );
  }
}

class _DoseRow extends StatelessWidget {
  const _DoseRow({
    required this.item,
    required this.onTake,
    required this.onSkip,
  });

  final DoseItem item;
  final VoidCallback onTake;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final time = TimeOfDay.fromDateTime(
      item.dose.scheduledTime,
    ).format(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: Text(
              time,
              style: const TextStyle(
                color: Colors.black45,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.dose.medicationName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                if (item.dose.dosage.isNotEmpty)
                  Text(
                    item.dose.dosage,
                    style: const TextStyle(fontSize: 12, color: Colors.black45),
                  ),
              ],
            ),
          ),
          if (item.isSubmitting)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else if (item.status != null)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  item.status == DoseLogStatus.taken
                      ? Icons.check_circle_outline
                      : Icons.block,
                  size: 18,
                  color: item.status == DoseLogStatus.taken
                      ? Colors.green
                      : Colors.orange,
                ),
                const SizedBox(width: 4),
                Text(
                  item.status == DoseLogStatus.taken ? 'Taken' : 'Skipped',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: item.status == DoseLogStatus.taken
                        ? Colors.green
                        : Colors.orange,
                  ),
                ),
              ],
            )
          else
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FilledButton(
                  onPressed: onTake,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: const TextStyle(fontSize: 13),
                  ),
                  child: const Text('Take'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: onSkip,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: const TextStyle(fontSize: 13),
                  ),
                  child: const Text('Skip'),
                ),
              ],
            ),
        ],
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
            'No medications yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap Add + to add your first medication.',
            style: TextStyle(color: Colors.black38),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: onAdd,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF4E84E5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text('Add medication'),
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
  const _MedicationCard({required this.medication});
  final Medication medication;

  @override
  State<_MedicationCard> createState() => _MedicationCardState();
}

class _MedicationCardState extends State<_MedicationCard> {
  bool _expanded = false;

  Color get _textColor {
    final lum = widget.medication.color.computeLuminance();
    return lum > 0.4 ? Colors.black87 : Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: widget.medication.color,
        borderRadius: BorderRadius.circular(28),
      ),
      child: _expanded
          ? _ExpandedBody(
              med: widget.medication,
              textColor: _textColor,
              onCollapse: () => setState(() => _expanded = false),
            )
          : _CollapsedBody(
              med: widget.medication,
              textColor: _textColor,
              onExpand: () => setState(() => _expanded = true),
            ),
    );
  }
}

class _CollapsedBody extends StatelessWidget {
  const _CollapsedBody({
    required this.med,
    required this.textColor,
    required this.onExpand,
  });
  final Medication med;
  final Color textColor;
  final VoidCallback onExpand;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Row(
        children: [
          Text(
            med.name,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: onExpand,
            child: Text(
              'info +',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textColor.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpandedBody extends StatelessWidget {
  const _ExpandedBody({
    required this.med,
    required this.textColor,
    required this.onCollapse,
  });
  final Medication med;
  final Color textColor;
  final VoidCallback onCollapse;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // name row
          Text(
            med.name,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // colour swatch
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: med.color,
                  border: Border.all(color: Colors.white, width: 2),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // detail bullets
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (med.dosage != null)
                      _Bullet(text: med.dosage!, color: textColor),
                    if (med.frequency != null)
                      _Bullet(text: med.frequency!, color: textColor),
                    if (med.notes != null && med.notes!.isNotEmpty)
                      _Bullet(text: med.notes!, color: textColor, italic: true),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.center,
            child: GestureDetector(
              onTap: onCollapse,
              child: Text(
                'info -',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textColor.withValues(alpha: 0.8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.text, required this.color, this.italic = false});
  final String text;
  final Color color;
  final bool italic;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontStyle: italic ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
