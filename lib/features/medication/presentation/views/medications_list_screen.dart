import 'package:flutter/material.dart';
import 'package:clinic_go/core/di/service_locator.dart';
import 'package:clinic_go/features/medication/data/medication_repository.dart';
import 'package:clinic_go/features/medication/models/medication.dart';
import 'package:clinic_go/features/medication/presentation/view_models/medications_list_view_model.dart';
import 'package:clinic_go/features/medication/presentation/views/add_medication_screen.dart';

/// Medication list embedded in the main shell at nav-bar index 1.
/// Displays coloured cards (colour = chosen colour from add form).
class MedicationsListScreen extends StatefulWidget {
  const MedicationsListScreen({super.key});

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
