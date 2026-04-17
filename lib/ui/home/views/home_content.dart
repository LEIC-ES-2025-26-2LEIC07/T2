import 'package:clinic_go/ui/core/themes/app_colors.dart';
import 'package:clinic_go/ui/home/data/dose_logs_repository.dart';
import 'package:clinic_go/ui/home/models/scheduled_dose.dart';
import 'package:clinic_go/ui/home/view_models/daily_doses_controller.dart';
import 'package:clinic_go/ui/home/views/dose_logging_sheet.dart';
import 'package:flutter/material.dart';

class HomeContent extends StatefulWidget {
  const HomeContent({super.key, this.controller, this.initialDoseRequest});

  final DailyDosesController? controller;
  final DoseLoggingRequest? initialDoseRequest;

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  late final DailyDosesController _controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller =
        widget.controller ??
        DailyDosesController(
          repository: _buildRepository(),
          initialDoses: _buildTodayDoses(),
        );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final request = widget.initialDoseRequest;
      if (request == null) {
        return;
      }

      final dose = _controller.doses.cast<ScheduledDose?>().firstWhere(
        (item) =>
            item?.medicationId == request.medicationId &&
            item?.scheduledTime.isAtSameMomentAs(request.scheduledTime) == true,
        orElse: () => null,
      );

      if (dose != null && mounted) {
        showDoseLoggingSheet(
          context: context,
          controller: _controller,
          dose: dose,
        );
      }
    });
  }

  DoseLogsRepository _buildRepository() {
    try {
      return SupabaseDoseLogsRepository();
    } catch (_) {
      return UnauthenticatedDoseLogsRepository();
    }
  }

  @override
  void dispose() {
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 92, bottom: 106),
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F0EA),
                borderRadius: BorderRadius.circular(36),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Plano do dia',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                      letterSpacing: -0.7,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Regista cada toma para manteres o teu tratamento em dia.',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.black.withValues(alpha: 0.65),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (!_controller.isAuthenticated)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Text(
                        'Inicia sessão para guardar as tuas tomas no historico.',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  if (!_controller.isAuthenticated) const SizedBox(height: 20),
                  Expanded(
                    child: _controller.doses.isEmpty
                        ? const _EmptyDailyDosesState()
                        : ListView.separated(
                            itemCount: _controller.doses.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              final dose = _controller.doses[index];
                              return _DoseCard(
                                dose: dose,
                                isAuthenticated: _controller.isAuthenticated,
                                onTake: () => _handleDoseAction(
                                  dose,
                                  DoseLogStatus.taken,
                                ),
                                onSkip: () => _handleDoseAction(
                                  dose,
                                  DoseLogStatus.skipped,
                                ),
                                onOpenSheet: () => showDoseLoggingSheet(
                                  context: context,
                                  controller: _controller,
                                  dose: dose,
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleDoseAction(
    ScheduledDose dose,
    DoseLogStatus status,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await _controller.logDose(
      medicationId: dose.medicationId,
      scheduledTime: dose.scheduledTime,
      status: status,
    );

    if (!mounted || result.message == null) {
      return;
    }

    if (result.outcome == DoseLogOutcome.failure ||
        result.outcome == DoseLogOutcome.authRequired) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(result.message!)));
    }
  }

  List<ScheduledDose> _buildTodayDoses() {
    final now = DateTime.now();
    return [
      ScheduledDose(
        medicationId: 'med-001',
        medicationName: 'Lisinopril',
        dosage: '10 mg',
        scheduledTime: DateTime(now.year, now.month, now.day, 8),
      ),
      ScheduledDose(
        medicationId: 'med-002',
        medicationName: 'Metformina',
        dosage: '500 mg',
        scheduledTime: DateTime(now.year, now.month, now.day, 13),
      ),
      ScheduledDose(
        medicationId: 'med-003',
        medicationName: 'Vitamina D',
        dosage: '1 capsula',
        scheduledTime: DateTime(now.year, now.month, now.day, 20),
      ),
    ];
  }
}

class DoseLoggingRequest {
  const DoseLoggingRequest({
    required this.medicationId,
    required this.scheduledTime,
  });

  final String medicationId;
  final DateTime scheduledTime;
}

class _DoseCard extends StatelessWidget {
  const _DoseCard({
    required this.dose,
    required this.isAuthenticated,
    required this.onTake,
    required this.onSkip,
    required this.onOpenSheet,
  });

  final ScheduledDose dose;
  final bool isAuthenticated;
  final VoidCallback onTake;
  final VoidCallback onSkip;
  final VoidCallback onOpenSheet;

  @override
  Widget build(BuildContext context) {
    final isCompleted = dose.isCompleted;
    final backgroundColor = isCompleted
        ? const Color(0xFFDDEAD9)
        : AppColors.white.withValues(alpha: 0.92);

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        onTap: onOpenSheet,
        borderRadius: BorderRadius.circular(28),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(
                      isCompleted
                          ? Icons.check_circle
                          : Icons.medication_outlined,
                      color: isCompleted
                          ? const Color(0xFF2E7D32)
                          : Colors.black,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dose.medicationName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${dose.dosage} • ${_formatTime(dose.scheduledTime)}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black.withValues(alpha: 0.65),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (dose.isSyncing)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                _statusLabel(dose),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isCompleted ? const Color(0xFF2E7D32) : Colors.black87,
                ),
              ),
              if (dose.loggedAt != null) ...[
                const SizedBox(height: 6),
                Text(
                  'Registado as ${_formatTime(dose.loggedAt!)}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black.withValues(alpha: 0.58),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              if (!isCompleted)
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        key: Key('take_${dose.medicationId}'),
                        onPressed: isAuthenticated && !dose.isSyncing
                            ? onTake
                            : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Tomar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        key: Key('skip_${dose.medicationId}'),
                        onPressed: isAuthenticated && !dose.isSyncing
                            ? onSkip
                            : null,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Ignorar'),
                      ),
                    ),
                  ],
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.78),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    dose.status == DoseLogStatus.taken
                        ? 'Toma concluida'
                        : 'Dose ignorada',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _statusLabel(ScheduledDose dose) {
    switch (dose.status) {
      case DoseLogStatus.pending:
        return 'Pendente';
      case DoseLogStatus.taken:
        return 'Tomada com sucesso';
      case DoseLogStatus.skipped:
        return 'Ignorada por ti';
    }
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _EmptyDailyDosesState extends StatelessWidget {
  const _EmptyDailyDosesState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Text(
          'Nao tens tomas agendadas para hoje.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: Colors.black.withValues(alpha: 0.65),
          ),
        ),
      ),
    );
  }
}
