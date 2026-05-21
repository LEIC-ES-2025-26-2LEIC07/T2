import 'package:clinic_go/core/routing/app_router.dart';
import 'package:clinic_go/core/themes/app_colors.dart';
import 'package:clinic_go/features/symptoms/models/symptom_log.dart';
import 'package:clinic_go/features/symptoms/presentation/view_models/symptom_history_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class SymptomHistoryScreen extends ConsumerWidget {
  const SymptomHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(symptomHistoryProvider);

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.paper,
          image: DecorationImage(
            image: AssetImage('assets/images/wallpaper-sky.png'),
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const _SymptomHistoryHeader(),
              Expanded(
                child: historyAsync.when(
                  data: (logs) {
                    if (logs.isEmpty) {
                      return const _EmptySymptomHistory();
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
                      itemCount: logs.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        return _SymptomTimelineCard(log: logs[index]);
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stackTrace) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Não foi possível carregar o histórico de sintomas.\n$error',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SymptomHistoryHeader extends StatelessWidget {
  const _SymptomHistoryHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 14, 24, 0),
      child: Row(
        children: [
          SizedBox(
            width: 38,
            height: 38,
            child: IconButton(
              padding: EdgeInsets.zero,
              onPressed: () => Navigator.of(context).maybePop(),
              style: IconButton.styleFrom(
                backgroundColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  side: const BorderSide(color: AppColors.ink, width: 2),
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
              icon: const Icon(
                Icons.chevron_left,
                color: AppColors.ink,
                size: 30,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Histórico de sintomas',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptySymptomHistory extends StatelessWidget {
  const _EmptySymptomHistory();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.maxHeight;
        final minContentHeight = availableHeight > 40
            ? availableHeight - 40
            : 0.0;
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minContentHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 18),
                const _SymptomEmptyIllustration(),
                const SizedBox(height: 24),
                const Text(
                  'Sem registos ainda',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 10),
                const SizedBox(
                  width: 230,
                  child: Text(
                    'O teu histórico de sintomas aparece aqui depois do primeiro registo.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      height: 1.25,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  height: 46,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(color: AppColors.ink, offset: Offset(4, 4)),
                    ],
                  ),
                  child: FilledButton.icon(
                    onPressed: () =>
                        Navigator.of(context).pushNamed(AppRouter.logSymptom),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Registar agora'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.lemon,
                      foregroundColor: AppColors.card,
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(color: AppColors.ink, width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      textStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SymptomEmptyIllustration extends StatelessWidget {
  const _SymptomEmptyIllustration();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 126,
      height: 126,
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.ink, width: 2),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [BoxShadow(color: AppColors.ink, offset: Offset(4, 4))],
      ),
      child: Center(
        child: SizedBox(
          width: 54,
          height: 60,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                top: 6,
                right: 5,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFC9DCF7),
                    border: Border.all(color: AppColors.ink, width: 2),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 12, 8, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _IllustrationLine(width: 26),
                        const SizedBox(height: 7),
                        _IllustrationLine(width: 22),
                        const SizedBox(height: 7),
                        _IllustrationLine(width: 28),
                        const SizedBox(height: 7),
                        _IllustrationLine(width: 18),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: AppColors.lemon,
                    border: Border.all(color: AppColors.ink, width: 1.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: AppColors.card,
                    size: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IllustrationLine extends StatelessWidget {
  const _IllustrationLine({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 2,
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _SymptomTimelineCard extends StatelessWidget {
  const _SymptomTimelineCard({required this.log});

  final SymptomLog log;

  @override
  Widget build(BuildContext context) {
    final occurredAt = DateFormat(
      'EEEE, MMM d - h:mm a',
    ).format(log.occurredAt.toLocal());

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.severityColor(
                    log.severity,
                  ).withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Severity ${log.severity}',
                  style: TextStyle(
                    color: AppColors.severityColor(log.severity),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              const Icon(Icons.access_time, size: 18, color: AppColors.muted),
              const SizedBox(width: 6),
              Text(occurredAt, style: const TextStyle(color: AppColors.muted)),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            log.symptomLabel,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          if (log.notes != null && log.notes!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              log.notes!,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.muted,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
