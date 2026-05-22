import 'package:flutter/material.dart';

import 'package:clinic_go/core/di/service_locator.dart';

import 'package:clinic_go/features/medication/data/dose_log_repository.dart';
import 'package:clinic_go/features/medication/data/medication_repository.dart';
import 'package:clinic_go/features/medication/services/dose_scheduling_service.dart';
import 'package:clinic_go/features/medication/services/missed_dose_notification_controller.dart';
import 'package:clinic_go/features/medication/presentation/view_models/daily_doses_view_model.dart';

class DailyDosesScreen extends StatefulWidget {
  const DailyDosesScreen({super.key, this.viewModel});

  final DailyDosesViewModel? viewModel;

  @override
  State<DailyDosesScreen> createState() => _DailyDosesScreenState();
}

class _DailyDosesScreenState extends State<DailyDosesScreen> {
  late final DailyDosesViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel =
        widget.viewModel ??
        DailyDosesViewModel(
          repository: getIt<MedicationRepository>(),
          schedulingService: getIt<DoseSchedulingService>(),
          logRepository: getIt<DoseLogRepository>(),
          notificationController: getIt<MissedDoseNotificationController>(),
        );

    if (widget.viewModel == null) {
      _viewModel.loadTodayDoses();
    }
  }

  @override
  void dispose() {
    if (widget.viewModel == null) {
      _viewModel.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agenda de Hoje')),
      body: AnimatedBuilder(
        animation: _viewModel,
        builder: (context, _) {
          if (_viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_viewModel.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_viewModel.errorMessage!),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _viewModel.loadTodayDoses,
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            );
          }

          final doses = _viewModel.doses;
          if (doses.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.event_available_outlined,
                    size: 64,
                    color: Colors.black38,
                  ),
                  const SizedBox(height: 12),
                  const Text('Sem doses agendadas para hoje.'),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: doses.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final item = doses[i];
              final scheduledLabel = TimeOfDay.fromDateTime(
                item.dose.scheduledTime,
              ).format(context);

              final completed = item.status != null;

              return Card(
                color: completed ? Colors.grey.shade200 : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.dose.medicationName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${item.dose.dosage} • $scheduledLabel',
                                  style: const TextStyle(color: Colors.black54),
                                ),
                              ],
                            ),
                          ),
                          if (completed)
                            const Icon(Icons.check_circle, color: Colors.green)
                          else
                            const SizedBox.shrink(),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (!completed)
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton(
                                onPressed: item.isSubmitting
                                    ? null
                                    : () async {
                                        final messenger = ScaffoldMessenger.of(
                                          context,
                                        );
                                        final navigator = Navigator.of(context);
                                        try {
                                          await _viewModel.logDose(
                                            dose: item.dose,
                                            status: DoseLogStatus.taken,
                                          );
                                          if (!mounted) return;
                                          messenger.showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Dose marcada como tomada.',
                                              ),
                                            ),
                                          );
                                          navigator.pop(true);
                                        } catch (e) {
                                          if (!mounted) return;
                                          messenger.showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Erro de rede. Tenta novamente.',
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                child: item.isSubmitting
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text('Tomar'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton(
                              onPressed: item.isSubmitting
                                  ? null
                                  : () async {
                                      final messenger = ScaffoldMessenger.of(
                                        context,
                                      );
                                      final navigator = Navigator.of(context);
                                      try {
                                        await _viewModel.logDose(
                                          dose: item.dose,
                                          status: DoseLogStatus.skipped,
                                        );
                                        if (!mounted) return;
                                        messenger.showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Dose marcada como ignorada.',
                                            ),
                                          ),
                                        );
                                        navigator.pop(true);
                                      } catch (e) {
                                        if (!mounted) return;
                                        messenger.showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Network error. Please try again.',
                                            ),
                                          ),
                                        );
                                      }
                                    },
                              child: const Text('Ignorar'),
                            ),
                          ],
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Text(
                            'Concluído às ${item.takenTime != null ? TimeOfDay.fromDateTime(item.takenTime!).format(context) : ''}',
                            style: const TextStyle(color: Colors.black54),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
