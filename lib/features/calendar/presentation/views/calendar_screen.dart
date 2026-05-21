import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:clinic_go/core/di/service_locator.dart';
import 'package:clinic_go/features/calendar/presentation/view_models/calendar_view_model.dart';
import 'package:clinic_go/features/calendar/data/calendar_repository.dart';
import 'package:clinic_go/features/medication/data/dose_log_repository.dart';
import 'package:clinic_go/features/medication/data/medication_repository.dart';
import 'package:clinic_go/features/medication/services/dose_scheduling_service.dart';
import 'package:clinic_go/core/themes/app_colors.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key, this.viewModel});

  final CalendarViewModel? viewModel;

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late final CalendarViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel =
        widget.viewModel ??
            CalendarViewModel(
              calendarRepository: getIt<CalendarRepository>(),
              medRepository: getIt<MedicationRepository>(),
              schedulingService: getIt<DoseSchedulingService>(),
            );
    if (widget.viewModel == null) {
      _viewModel.loadMonth(DateTime.now());
    }
  }

  @override
  void dispose() {
    if (widget.viewModel == null) _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Plano')),
      body: AnimatedBuilder(
        animation: _viewModel,
        builder: (context, _) {
          if (_viewModel.isLoading) return const Center(child: CircularProgressIndicator());
          if (_viewModel.error != null) return Center(child: Text(_viewModel.error!));

          final month = _viewModel.currentMonth;
          final header = DateFormat.MMMM().format(month) + ' ${month.year}';
          final summaries = _viewModel.summaries;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
                child: Row(
                  children: [
                    IconButton(onPressed: _viewModel.goToPreviousMonth, icon: const Icon(Icons.chevron_left)),
                    Expanded(
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
                          decoration: BoxDecoration(
                            color: AppColors.lemon,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.ink, width: 2),
                          ),
                          child: Text(
                            header,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                    IconButton(onPressed: _viewModel.goToNextMonth, icon: const Icon(Icons.chevron_right)),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: const [
                    _LegendItem(color: AppColors.mint, label: 'Tudo OK'),
                    _LegendItem(color: AppColors.lemon, label: 'Parcial'),
                    _LegendItem(color: AppColors.coral, label: 'Falhou'),
                    _LegendItem(color: AppColors.sky, label: 'Próximo'),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: _buildWeekdayHeader(),
              ),

              const SizedBox(height: 6),

              Expanded(
                child: _buildGrid(summaries, month),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildWeekdayHeader() {
    const weekdays = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
    return Row(
      children: weekdays
          .map((d) => Expanded(
                child: Center(
                  child: Text(
                    d,
                    style: TextStyle(color: AppColors.ink.withOpacity(0.75), fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildGrid(List<DaySummary> summaries, DateTime month) {
    final firstWeekday = DateTime(month.year, month.month, 1).weekday; // 1 = Mon
    final daysInMonth = summaries.length;

    final rows = <Widget>[];
    var dayIndex = 1 - (firstWeekday - 1);

    while (dayIndex <= daysInMonth) {
      final children = <Widget>[];
      for (var col = 0; col < 7; col++) {
        if (dayIndex < 1 || dayIndex > daysInMonth) {
          children.add(const Expanded(child: SizedBox()));
        } else {
          final summary = summaries[dayIndex - 1];
          children.add(
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(6.0),
                child: AspectRatio(aspectRatio: 1, child: _DayCell(summary: summary, onTap: _onDayTap)),
              ),
            ),
          );
        }
        dayIndex++;
      }
      rows.add(Row(children: children));
    }

    return Padding(padding: const EdgeInsets.symmetric(horizontal: 8.0), child: Column(children: rows));
  }

  void _onDayTap(DaySummary summary) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) {
        final all = <Widget>[];
        if (summary.scheduled.isEmpty && summary.logs.isEmpty) {
          all.add(const Padding(padding: EdgeInsets.all(16), child: Text('Sem atividade de medicação neste dia.')));
        } else {
          for (final s in summary.scheduled) {
            all.add(ListTile(leading: const Icon(Icons.schedule), title: Text('${s.medicationName} • ${s.dosage}'), subtitle: Text('Agendado: ${TimeOfDay.fromDateTime(s.scheduledTime).format(context)}')));
          }
          for (final l in summary.logs) {
            all.add(ListTile(
              leading: Icon(l.status == DoseLogStatus.taken ? Icons.check_circle : Icons.block, color: l.status == DoseLogStatus.taken ? AppColors.mint : AppColors.lemon),
              title: Text(l.medicationName ?? ''),
              subtitle: Text('Registado: ${l.takenTime != null ? TimeOfDay.fromDateTime(l.takenTime!).format(context) : ''} (${l.status.name})'),
            ));
          }
        }

        return SafeArea(child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: all)));
      },
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({required this.summary, required this.onTap});
  final DaySummary summary;
  final void Function(DaySummary) onTap;

  @override
  Widget build(BuildContext context) {
    final day = summary.date.day;
    final today = DateTime.now();
    final isToday = summary.date.year == today.year && summary.date.month == today.month && summary.date.day == today.day;

    Color? bg;
    switch (summary.status) {
      case DaySummaryStatus.allTaken:
        bg = AppColors.mint.withOpacity(0.9);
        break;
      case DaySummaryStatus.partial:
        bg = AppColors.lemon.withOpacity(0.9);
        break;
      case DaySummaryStatus.missed:
        bg = AppColors.coral.withOpacity(0.9);
        break;
      case DaySummaryStatus.upcoming:
        bg = AppColors.lemon.withOpacity(0.6);
        break;
      case DaySummaryStatus.none:
        bg = AppColors.card;
        break;
    }

    return GestureDetector(
      onTap: () => onTap(summary),
      child: Container(
        margin: const EdgeInsets.all(6),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: isToday ? AppColors.card : bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isToday ? AppColors.lemon : AppColors.ink.withOpacity(0.15), width: isToday ? 2 : 1),
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(day.toString(), style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink, fontSize: 16)),
                const SizedBox(height: 6),
                if (summary.status != DaySummaryStatus.none)
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.6), shape: BoxShape.circle),
                    child: Icon(_iconFor(summary.status), size: 16, color: _colorFor(summary.status)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _iconFor(DaySummaryStatus s) {
    switch (s) {
      case DaySummaryStatus.allTaken:
        return Icons.check_circle;
      case DaySummaryStatus.partial:
        return Icons.report_problem;
      case DaySummaryStatus.missed:
        return Icons.error;
      case DaySummaryStatus.upcoming:
        return Icons.schedule;
      default:
        return Icons.circle;
    }
  }

  Color _colorFor(DaySummaryStatus s) {
    switch (s) {
      case DaySummaryStatus.allTaken:
        return AppColors.mint;
      case DaySummaryStatus.partial:
        return AppColors.lemon;
      case DaySummaryStatus.missed:
        return AppColors.coral;
      case DaySummaryStatus.upcoming:
        return AppColors.lemon;
      default:
        return AppColors.ink.withOpacity(0.6);
    }
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4), border: Border.all(color: AppColors.ink, width: 1.5))),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    );
  }
}
