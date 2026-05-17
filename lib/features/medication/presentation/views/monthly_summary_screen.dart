import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:clinic_go/core/themes/app_colors.dart';
import 'package:clinic_go/features/medication/presentation/view_models/monthly_summary_providers.dart';
import 'package:clinic_go/features/medication/presentation/widgets/monthly_summary_calendar.dart';

class MonthlySummaryScreen extends ConsumerWidget {
  const MonthlySummaryScreen({super.key, this.showAppBar = true});

  final bool showAppBar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMonth = ref.watch(selectedMonthProvider);
    final summary = ref.watch(monthlyLogsProvider(selectedMonth));

    return Scaffold(
      backgroundColor: showAppBar ? AppColors.background : Colors.transparent,
      appBar: showAppBar ? AppBar(title: const Text('Resumo mensal')) : null,
      body: SafeArea(
        child: summary.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _ErrorState(
            onRetry: () => ref.invalidate(monthlyLogsProvider(selectedMonth)),
          ),
          data: (data) => RefreshIndicator(
            onRefresh: () =>
                ref.refresh(monthlyLogsProvider(selectedMonth).future),
            child: ListView(
              padding: EdgeInsets.fromLTRB(20, showAppBar ? 16 : 88, 20, 116),
              children: [
                _MonthSelector(month: selectedMonth),
                const SizedBox(height: 16),
                _SummaryCard(percentage: data.adherencePercentage),
                const SizedBox(height: 16),
                if (data.logs.isEmpty)
                  const _EmptyState()
                else
                  MonthlySummaryCalendar(month: selectedMonth, summary: data),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MonthSelector extends ConsumerWidget {
  const _MonthSelector({required this.month});

  final DateTime month;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        IconButton.filledTonal(
          tooltip: 'Mês anterior',
          onPressed: () =>
              _setMonth(ref, DateTime(month.year, month.month - 1)),
          icon: const Icon(Icons.chevron_left),
        ),
        Expanded(
          child: Text(
            _monthLabel(month),
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        IconButton.filledTonal(
          tooltip: 'Mês seguinte',
          onPressed: () =>
              _setMonth(ref, DateTime(month.year, month.month + 1)),
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }

  void _setMonth(WidgetRef ref, DateTime value) {
    ref.read(selectedMonthProvider.notifier).setMonth(value);
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.percentage});

  final int? percentage;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: AppColors.shadow, blurRadius: 18)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Adesão geral',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            percentage == null ? 'N/A' : '$percentage%',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: AppColors.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        children: [
          Icon(Icons.calendar_month_outlined, size: 56, color: Colors.black38),
          SizedBox(height: 12),
          Text(
            'Sem dados neste mês',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 56, color: Color(0xFFC62828)),
            const SizedBox(height: 12),
            const Text(
              'Não foi possível carregar o resumo mensal.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onRetry,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}

String _monthLabel(DateTime month) {
  const months = [
    'Janeiro',
    'Fevereiro',
    'Março',
    'Abril',
    'Maio',
    'Junho',
    'Julho',
    'Agosto',
    'Setembro',
    'Outubro',
    'Novembro',
    'Dezembro',
  ];
  return '${months[month.month - 1]} ${month.year}';
}
