import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:clinic_go/features/medication/models/monthly_medication_log.dart';
import 'package:clinic_go/features/medication/presentation/view_models/monthly_summary_providers.dart';

class MonthlySummaryCalendar extends StatelessWidget {
  const MonthlySummaryCalendar({
    super.key,
    required this.month,
    required this.summary,
  });

  final DateTime month;
  final MonthlySummary summary;

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    final firstWeekday = DateTime(month.year, month.month).weekday;
    final leadingEmptyCells = firstWeekday % 7;
    final itemCount = leadingEmptyCells + daysInMonth;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const _WeekdayHeader(),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: itemCount,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemBuilder: (context, index) {
              if (index < leadingEmptyCells) return const SizedBox.shrink();

              final day = index - leadingEmptyCells + 1;
              final logs = summary.logsByDay[day] ?? const [];
              final status = summary.statusForDay(day);

              return _CalendarDayCell(
                day: day,
                status: status,
                hasLogs: logs.isNotEmpty,
                onTap: logs.isEmpty
                    ? null
                    : () => _showDayDetails(
                        context,
                        DateTime(month.year, month.month, day),
                        logs,
                      ),
              );
            },
          ),
          const SizedBox(height: 16),
          const _Legend(),
        ],
      ),
    );
  }
}

class _WeekdayHeader extends StatelessWidget {
  const _WeekdayHeader();

  @override
  Widget build(BuildContext context) {
    const labels = ['D', 'S', 'T', 'Q', 'Q', 'S', 'S'];
    return Row(
      children: labels
          .map(
            (label) => Expanded(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.black54,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({
    required this.day,
    required this.status,
    required this.hasLogs,
    required this.onTap,
  });

  final int day;
  final DailyAdherenceStatus? status;
  final bool hasLogs;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    final textColor = status == null ? Colors.black87 : Colors.white;

    return Material(
      color: color,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Center(
          child: Text(
            '$day',
            style: TextStyle(
              color: textColor,
              fontWeight: hasLogs ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Color _statusColor(DailyAdherenceStatus? status) {
    return switch (status) {
      DailyAdherenceStatus.allTaken => const Color(0xFF2E7D32),
      DailyAdherenceStatus.partial => const Color(0xFFF9A825),
      DailyAdherenceStatus.missed => const Color(0xFFC62828),
      null => const Color(0xFFEDEDED),
    };
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        _LegendItem(color: Color(0xFF2E7D32), label: 'all_taken'),
        _LegendItem(color: Color(0xFFF9A825), label: 'partial'),
        _LegendItem(color: Color(0xFFC62828), label: 'missed'),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: Colors.black54)),
      ],
    );
  }
}

void _showDayDetails(
  BuildContext context,
  DateTime day,
  List<MonthlyMedicationLog> logs,
) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      return SafeArea(
        child: ListView.separated(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          itemCount: logs.length + 1,
          separatorBuilder: (_, index) =>
              index == 0 ? const SizedBox(height: 8) : const Divider(),
          itemBuilder: (context, index) {
            if (index == 0) {
              return Text(
                DateFormat('dd/MM/yyyy').format(day),
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              );
            }
            final log = logs[index - 1];
            final time = DateFormat.Hm().format(log.takenAt);
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                log.wasTaken ? Icons.check_circle : Icons.cancel,
                color: log.wasTaken
                    ? const Color(0xFF2E7D32)
                    : const Color(0xFFC62828),
              ),
              title: Text(log.medicationName),
              subtitle: Text('${log.dosage} • $time'),
              trailing: Text(log.wasTaken ? 'Tomado' : 'Falhado'),
            );
          },
        ),
      );
    },
  );
}
