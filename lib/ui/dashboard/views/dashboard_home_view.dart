import 'package:clinic_go/core/providers/supabase_providers.dart';
import 'package:clinic_go/ui/common/widgets/custom_search_bar.dart';
import 'package:clinic_go/ui/core/themes/app_colors.dart';
import 'package:clinic_go/ui/symptoms/models/symptom_log.dart';
import 'package:clinic_go/ui/symptoms/view_models/symptom_history_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class DashboardHomeView extends ConsumerWidget {
  const DashboardHomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final historyAsync = ref.watch(symptomHistoryProvider);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 72),
            Text(
              'Track how you feel',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Log symptoms in seconds and keep a clear timeline ready for your care team.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.muted,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),
            const CustomSearchBar(
              hintText: 'Search support, doctors, or care plans',
            ),
            const SizedBox(height: 24),
            _QuickActionsCard(currentUser: currentUser != null),
            const SizedBox(height: 20),
            if (currentUser == null)
              const _AuthHintCard()
            else
              _RecentSymptomsCard(historyAsync: historyAsync),
          ],
        ),
      ),
    );
  }
}

class _QuickActionsCard extends StatelessWidget {
  const _QuickActionsCard({required this.currentUser});

  final bool currentUser;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1C6E8C), Color(0xFF2E8B57)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x221C6E8C),
            blurRadius: 28,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Symptoms',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Capture pain, fatigue, mood, or any other changes while they are fresh.',
            style: TextStyle(color: Colors.white, height: 1.45),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.icon(
                onPressed: currentUser
                    ? () => context.push('/dashboard/log-symptom')
                    : null,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.ink,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                ),
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Log symptom'),
              ),
              OutlinedButton.icon(
                onPressed: currentUser
                    ? () => context.push('/dashboard/symptom-history')
                    : null,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.7)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                ),
                icon: const Icon(Icons.timeline_outlined),
                label: const Text('View history'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AuthHintCard extends StatelessWidget {
  const _AuthHintCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sign in required',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            'Symptom logging is protected by your Supabase session. Once authentication is wired up, these tools will unlock automatically for signed-in users.',
          ),
        ],
      ),
    );
  }
}

class _RecentSymptomsCard extends StatelessWidget {
  const _RecentSymptomsCard({required this.historyAsync});

  final AsyncValue<List<SymptomLog>> historyAsync;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: historyAsync.when(
        data: (logs) {
          if (logs.isEmpty) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recent history',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                const Text(
                  'No symptoms logged yet. Your next check-in will appear here.',
                ),
              ],
            );
          }

          final preview = logs.take(3).toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent history',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push('/dashboard/symptom-history'),
                    child: const Text('See all'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              for (final log in preview) ...[
                _HistoryPreviewRow(
                  title: log.symptomLabel,
                  severity: log.severity,
                  occurredAt: log.occurredAt,
                ),
                const SizedBox(height: 12),
              ],
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent history',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text('Unable to load symptom history right now.\n$error'),
          ],
        ),
      ),
    );
  }
}

class _HistoryPreviewRow extends StatelessWidget {
  const _HistoryPreviewRow({
    required this.title,
    required this.severity,
    required this.occurredAt,
  });

  final String title;
  final int severity;
  final DateTime occurredAt;

  @override
  Widget build(BuildContext context) {
    final formatted = DateFormat('MMM d, h:mm a').format(occurredAt.toLocal());

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F6F3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.severityColor(
              severity,
            ).withValues(alpha: 0.18),
            child: Text(
              '$severity',
              style: TextStyle(
                color: AppColors.severityColor(severity),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(formatted, style: const TextStyle(color: AppColors.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
