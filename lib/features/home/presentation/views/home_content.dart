import 'package:flutter/material.dart';
import 'package:clinic_go/core/di/service_locator.dart';
import 'package:clinic_go/core/routing/app_router.dart';
import 'package:clinic_go/core/themes/app_colors.dart';
import 'package:clinic_go/features/auth/domain/auth_service.dart';
import 'package:clinic_go/features/medication/data/dose_log_repository.dart';
import 'package:clinic_go/features/medication/data/medication_repository.dart';
import 'package:clinic_go/features/medication/services/dose_scheduling_service.dart';
import 'package:clinic_go/features/medication/services/missed_dose_notification_controller.dart';
import 'package:clinic_go/features/medication/presentation/views/daily_doses_screen.dart';
import 'package:clinic_go/features/home/presentation/view_models/home_view_model.dart';
import 'package:clinic_go/features/home/presentation/widgets/home_header_bar.dart';
import 'package:clinic_go/features/home/presentation/widgets/home_next_dose_card.dart';
import 'package:clinic_go/features/home/presentation/widgets/home_quick_action_box.dart';
import 'package:clinic_go/features/home/presentation/widgets/home_today_plan.dart';

class HomeContent extends StatefulWidget {
  const HomeContent({
    super.key,
    this.viewModel,
    this.onDoseLogged,
    this.onGoToMeds,
  });

  final HomeViewModel? viewModel;
  final VoidCallback? onDoseLogged;
  final VoidCallback? onGoToMeds;

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  late final HomeViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel =
        widget.viewModel ??
        HomeViewModel(
          repository: getIt<MedicationRepository>(),
          schedulingService: getIt<DoseSchedulingService>(),
          logRepository: getIt<DoseLogRepository>(),
          notificationController: getIt<MissedDoseNotificationController>(),
        );
    if (widget.viewModel == null) {
      _viewModel.loadNextDose();
    }
  }

  @override
  void dispose() {
    if (widget.viewModel == null) {
      _viewModel.dispose();
    }
    super.dispose();
  }

  Future<void> _onDoseLoggingResult(Object? result) async {
    if (result == true) {
      _viewModel.doseLogged();
      _viewModel.loadNextDose();
      widget.onDoseLogged?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        if (_viewModel.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final now = DateTime.now();
        final nextDose = _viewModel.nextDose;
        final isOverdue = _viewModel.isOverdue;
        final firstName = _userFirstName();
        final greeting = firstName.isNotEmpty
            ? '${_buildGreeting(now)}, $firstName.'
            : '${_buildGreeting(now)}.';

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 56, 20, 110),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HomeHeaderBar(onGoToMeds: widget.onGoToMeds),
              const SizedBox(height: 16),
              Text(
                _buildDateLabel(now),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.6,
                  color: AppColors.ink,
                  height: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                greeting,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: AppColors.ink,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 18),
              HomeNextDoseCard(
                viewModel: _viewModel,
                nextDose: nextDose,
                isOverdue: isOverdue,
                now: now,
                onDoseLogged: widget.onDoseLogged,
                onGoToDailyDoses: () async {
                  final result = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(builder: (_) => const DailyDosesScreen()),
                  );
                  await _onDoseLoggingResult(result);
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: HomeQuickActionBox(
                      bg: AppColors.mint,
                      icon: const Icon(
                        Icons.add,
                        color: AppColors.paper,
                        size: 18,
                      ),
                      label: 'Registar sintoma',
                      sub: 'Como se sente?',
                      onTap: () =>
                          Navigator.of(context).pushNamed(AppRouter.logSymptom),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: HomeQuickActionBox(
                      bg: AppColors.sky,
                      icon: const Icon(
                        Icons.history,
                        color: AppColors.ink,
                        size: 18,
                      ),
                      label: 'Histórico',
                      sub: 'Últimos 7 dias',
                      onTap: () => Navigator.of(
                        context,
                      ).pushNamed(AppRouter.symptomHistory),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Plano de hoje',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 10),
              if (_viewModel.todayDoses.isEmpty)
                const HomeEmptyPlanCard()
              else
                HomeTodayPlanCard(entries: _viewModel.todayDoses, now: now),
            ],
          ),
        );
      },
    );
  }
}

String _buildDateLabel(DateTime now) {
  const days = [
    'SEGUNDA',
    'TERÇA',
    'QUARTA',
    'QUINTA',
    'SEXTA',
    'SÁBADO',
    'DOMINGO',
  ];
  const months = [
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
  return '${days[now.weekday - 1]} · ${now.day} ${months[now.month - 1]}';
}

String _buildGreeting(DateTime now) {
  final h = now.hour;
  if (h < 12) return 'Bom dia';
  if (h < 18) return 'Boa tarde';
  return 'Boa noite';
}

String _userFirstName() {
  try {
    final meta = getIt<AuthService>().currentUserMetadata;
    final name = ((meta['name'] ?? meta['full_name'] ?? '') as String).trim();
    if (name.isEmpty) return '';
    return name.split(' ').first;
  } catch (_) {
    return '';
  }
}
