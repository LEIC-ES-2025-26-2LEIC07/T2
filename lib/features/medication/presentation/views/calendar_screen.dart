import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:clinic_go/core/di/service_locator.dart';
import 'package:clinic_go/features/medication/presentation/view_models/calendar_view_model.dart';
import 'package:clinic_go/features/medication/data/dose_log_repository.dart';
import 'package:clinic_go/features/medication/data/calendar_repository.dart';
import 'package:clinic_go/features/medication/data/medication_repository.dart';
import 'package:clinic_go/features/medication/services/dose_scheduling_service.dart';

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
      appBar: AppBar(title: const Text('Calendar')),
      body: AnimatedBuilder(
        animation: _viewModel,
        builder: (context, _) {
          if (_viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (_viewModel.error != null) {
            return Center(child: Text(_viewModel.error!));
          }

          final month = _viewModel.currentMonth;
          final header = DateFormat.yMMMM().format(month);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _viewModel.goToPreviousMonth,
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          header,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _viewModel.goToNextMonth,
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
              ),
              _buildLegend(),
              const SizedBox(height: 8),
              Expanded(child: _buildGrid()),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: const [
          _LegendItem(color: Colors.green, label: 'All taken'),
          _LegendItem(color: Colors.orange, label: 'Partial'),
          _LegendItem(color: Colors.red, label: 'Missed'),
          _LegendItem(color: Colors.blue, label: 'Upcoming'),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    final summaries = _viewModel.summaries;
    final month = _viewModel.currentMonth;
    final firstWeekday = DateTime(
      month.year,
      month.month,
      1,
    ).weekday; // 1 = Mon
    final daysInMonth = summaries.length;

    final rows = <Widget>[];
    var dayIndex = 1 - (firstWeekday - 1); // start from Monday-based grid

    while (dayIndex <= daysInMonth) {
      final children = <Widget>[];
      for (var col = 0; col < 7; col++) {
        if (dayIndex < 1 || dayIndex > daysInMonth) {
          children.add(Expanded(child: Container()));
        } else {
          final summary = summaries[dayIndex - 1];
          children.add(
            Expanded(
              child: _DayCell(summary: summary, onTap: _onDayTap),
            ),
          );
        }
        dayIndex++;
      }
      rows.add(Row(children: children));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(children: rows),
    );
  }

  void _onDayTap(DaySummary summary) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) {
        final all = <Widget>[];
        if (summary.scheduled.isEmpty && summary.logs.isEmpty) {
          all.add(
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No medication activity for this day.'),
            ),
          );
        } else {
          for (final s in summary.scheduled) {
            all.add(
              ListTile(
                leading: const Icon(Icons.schedule),
                title: Text('${s.medicationName} • ${s.dosage}'),
                subtitle: Text(
                  'Scheduled: ${TimeOfDay.fromDateTime(s.scheduledTime).format(context)}',
                ),
              ),
            );
          }
          for (final l in summary.logs) {
            all.add(
              ListTile(
                leading: Icon(
                  l.status == DoseLogStatus.taken
                      ? Icons.check_circle
                      : Icons.block,
                  color: l.status == DoseLogStatus.taken
                      ? Colors.green
                      : Colors.orange,
                ),
                title: Text(l.medicationName ?? ''),
                subtitle: Text(
                  'Logged: ${l.takenTime != null ? TimeOfDay.fromDateTime(l.takenTime!).format(context) : ''} (${l.status.name})',
                ),
              ),
            );
          }
        }

        return SafeArea(
          child: Column(mainAxisSize: MainAxisSize.min, children: all),
        );
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
    final isToday =
        summary.date.year == today.year &&
        summary.date.month == today.month &&
        summary.date.day == today.day;

    Color? bg;
    switch (summary.status) {
      case DaySummaryStatus.allTaken:
        bg = Colors.green.shade200;
        break;
      case DaySummaryStatus.partial:
        bg = Colors.orange.shade200;
        break;
      case DaySummaryStatus.missed:
        bg = Colors.red.shade200;
        break;
      case DaySummaryStatus.upcoming:
        bg = Colors.blue.shade200;
        break;
      case DaySummaryStatus.none:
        bg = null;
        break;
    }

    return GestureDetector(
      onTap: () => onTap(summary),
      child: Container(
        margin: const EdgeInsets.all(6),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: isToday ? Colors.yellow.shade100 : bg ?? Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          children: [
            Text(
              day.toString(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            if (summary.status != DaySummaryStatus.none)
              Icon(
                _iconFor(summary.status),
                size: 18,
                color: _colorFor(summary.status),
              ),
          ],
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
        return Colors.green;
      case DaySummaryStatus.partial:
        return Colors.orange;
      case DaySummaryStatus.missed:
        return Colors.red;
      case DaySummaryStatus.upcoming:
        return Colors.blue;
      default:
        return Colors.grey;
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
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }
}
