import 'package:flutter/material.dart';
import 'package:clinic_go/core/di/service_locator.dart';
import 'package:clinic_go/core/themes/app_colors.dart';
import 'package:clinic_go/core/widgets/app_background.dart';
import 'package:clinic_go/features/calendar/data/calendar_repository.dart';
import 'package:clinic_go/features/calendar/presentation/view_models/calendar_view_model.dart';
import 'package:clinic_go/features/medication/data/dose_log_repository.dart';
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
  late DateTime _selectedDay;

  static const _ptMonthsShort = [
    'JAN',
    'FEV',
    'MAR',
    'ABR',
    'MAI',
    'JUN',
    'JUL',
    'AGO',
    'SET',
    'OUT',
    'NOV',
    'DEZ',
  ];

  static const _ptMonthsLong = [
    'janeiro',
    'fevereiro',
    'março',
    'abril',
    'maio',
    'junho',
    'julho',
    'agosto',
    'setembro',
    'outubro',
    'novembro',
    'dezembro',
  ];

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
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

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _monthLabel(DateTime d) => '${_ptMonthsShort[d.month - 1]} ${d.year}';

  String _dayLabel(DateTime d) => '${d.day} ${_ptMonthsLong[d.month - 1]}';

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: AnimatedBuilder(
            animation: _viewModel,
            builder: (context, _) {
              if (_viewModel.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (_viewModel.error != null) {
                return Center(child: Text(_viewModel.error!));
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 12),
                  _buildMonthNavigator(),
                  const SizedBox(height: 10),
                  _buildLegend(),
                  const SizedBox(height: 8),
                  _buildWeekdayRow(),
                  const SizedBox(height: 2),
                  _buildGrid(),
                  const SizedBox(height: 10),
                  _buildDosesPanel(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Text(
        'PLANO',
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w900,
          color: AppColors.ink,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildMonthNavigator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BrutalDecor.box(shadow: false),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          children: [
            _NavButton(
              icon: Icons.chevron_left,
              onTap: _viewModel.goToPreviousMonth,
            ),
            Expanded(
              child: Center(
                child: Text(
                  _monthLabel(_viewModel.currentMonth),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
            _NavButton(
              icon: Icons.chevron_right,
              onTap: _viewModel.goToNextMonth,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        children: const [
          _LegendChip(color: AppColors.mint, label: 'Todas tomadas'),
          _LegendChip(color: Color(0xFFFFD9A0), label: 'Parcial'),
          _LegendChip(color: AppColors.coral, label: 'Falhadas'),
          _LegendChip(color: AppColors.sky, label: 'Próximas'),
        ],
      ),
    );
  }

  Widget _buildWeekdayRow() {
    const labels = ['SEG', 'TER', 'QUA', 'QUI', 'SEX', 'SÁB', 'DOM'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: labels
            .map(
              (d) => Expanded(
                child: Center(
                  child: Text(
                    d,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: AppColors.muted,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildGrid() {
    final summaries = _viewModel.summaries;
    final month = _viewModel.currentMonth;
    final firstWeekday = DateTime(month.year, month.month, 1).weekday;
    final daysInMonth = summaries.length;

    final rows = <Widget>[];
    var dayIndex = 1 - (firstWeekday - 1);

    while (dayIndex <= daysInMonth) {
      final cells = <Widget>[];
      for (var col = 0; col < 7; col++) {
        if (dayIndex < 1 || dayIndex > daysInMonth) {
          cells.add(const Expanded(child: SizedBox()));
        } else {
          final summary = summaries[dayIndex - 1];
          cells.add(
            Expanded(
              child: _DayCell(
                summary: summary,
                isSelected: _isSameDay(summary.date, _selectedDay),
                onTap: () => setState(() => _selectedDay = summary.date),
              ),
            ),
          );
        }
        dayIndex++;
      }
      rows.add(Row(children: cells));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(children: rows),
    );
  }

  Widget _buildDosesPanel() {
    final summary = _viewModel.daySummaryFor(_selectedDay);
    final logs = summary?.logs ?? [];
    final scheduled = summary?.scheduled ?? [];

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Container(
          decoration: BrutalDecor.box(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Text(
                  _dayLabel(_selectedDay),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Divider(height: 1, color: AppColors.ink, thickness: 1),
              Expanded(
                child: logs.isEmpty && scheduled.isEmpty
                    ? const Center(
                        child: Text(
                          'Sem doses para este dia.',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 13,
                          ),
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.all(10),
                        children: [
                          ...logs.map(
                            (l) => _DoseCard(
                              name: l.medicationName ?? '',
                              time: TimeOfDay.fromDateTime(l.scheduledTime),
                              taken: l.status == DoseLogStatus.taken,
                            ),
                          ),
                          ...scheduled.map(
                            (s) => _DoseCard(
                              name: s.medicationName,
                              time: TimeOfDay.fromDateTime(s.scheduledTime),
                              taken: null,
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Month navigator button ────────────────────────────────────────────────────

class _NavButton extends StatelessWidget {
  const _NavButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.card,
          border: BrutalDecor.border,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.ink, size: 20),
      ),
    );
  }
}

// ── Legend chip ───────────────────────────────────────────────────────────────

class _LegendChip extends StatelessWidget {
  const _LegendChip({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        border: BrutalDecor.border,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: AppColors.ink,
        ),
      ),
    );
  }
}

// ── Day cell ──────────────────────────────────────────────────────────────────

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.summary,
    required this.isSelected,
    required this.onTap,
  });

  final DaySummary summary;
  final bool isSelected;
  final VoidCallback onTap;

  static Color _fillFor(DaySummaryStatus s) {
    switch (s) {
      case DaySummaryStatus.allTaken:
        return AppColors.mint;
      case DaySummaryStatus.partial:
        return const Color(0xFFFFD9A0);
      case DaySummaryStatus.missed:
        return AppColors.coral;
      case DaySummaryStatus.upcoming:
        return AppColors.sky;
      case DaySummaryStatus.none:
        return AppColors.card;
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final isToday =
        summary.date.year == today.year &&
        summary.date.month == today.month &&
        summary.date.day == today.day;

    final Color bg;
    if (isToday) {
      bg = AppColors.lemon;
    } else {
      bg = _fillFor(summary.status);
    }

    final hasStatus = summary.status != DaySummaryStatus.none || isToday;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(3),
        height: 44,
        decoration: BoxDecoration(
          color: bg,
          border: Border.fromBorderSide(
            BorderSide(color: AppColors.ink, width: isSelected ? 2.5 : 1.5),
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: hasStatus ? BrutalDecor.shadowSm : null,
        ),
        child: Center(
          child: Text(
            '${summary.date.day}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: isToday ? AppColors.card : AppColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Dose card ─────────────────────────────────────────────────────────────────

class _DoseCard extends StatelessWidget {
  const _DoseCard({
    required this.name,
    required this.time,
    required this.taken,
  });

  final String name;
  final TimeOfDay time;
  final bool? taken; // null = upcoming

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final String statusLabel;
    if (taken == null) {
      bg = AppColors.sky;
      statusLabel = 'agendada';
    } else if (taken!) {
      bg = AppColors.mint;
      statusLabel = 'tomada';
    } else {
      bg = AppColors.coral;
      statusLabel = 'falhada';
    }

    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        border: BrutalDecor.border,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: AppColors.ink,
              ),
            ),
          ),
          Text(
            '$hour:$minute',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.card,
              border: BrutalDecor.border,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              statusLabel,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
