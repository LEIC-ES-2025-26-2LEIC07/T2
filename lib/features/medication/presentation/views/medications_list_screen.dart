import 'package:flutter/material.dart';
import 'package:clinic_go/core/di/service_locator.dart';
import 'package:clinic_go/core/themes/app_colors.dart';
import 'package:clinic_go/core/widgets/clinic_go_logo.dart';
import 'package:clinic_go/features/medication/data/medication_repository.dart';
import 'package:clinic_go/features/medication/presentation/view_models/medications_list_view_model.dart';
import 'package:clinic_go/features/medication/presentation/views/add_medication_screen.dart';
import 'package:clinic_go/features/medication/presentation/widgets/medication_card.dart';
import 'package:clinic_go/features/medication/presentation/widgets/medication_list_states.dart';

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
            const ClinicGoLogo(),
            const SizedBox(height: 12),
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
                MedListAddButton(onTap: _openAddMedication),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: AnimatedBuilder(
                animation: _viewModel,
                builder: (context, _) {
                  if (_viewModel.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (_viewModel.errorMessage != null) {
                    return MedListErrorState(
                      message: _viewModel.errorMessage!,
                      onRetry: _viewModel.loadMedications,
                    );
                  }
                  if (_viewModel.medications.isEmpty) {
                    return MedListEmptyState(onAdd: _openAddMedication);
                  }
                  return ListView.separated(
                    itemCount: _viewModel.medications.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 16),
                    itemBuilder: (_, i) => MedicationCard(
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
