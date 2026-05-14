import 'dart:async';

import 'package:flutter/material.dart';
import 'package:clinic_go/core/di/service_locator.dart';
import 'package:clinic_go/core/themes/app_colors.dart';
import 'package:clinic_go/core/widgets/app_background.dart';
import 'package:clinic_go/core/widgets/floating_bottom_nav_bar.dart';
import 'package:clinic_go/features/auth/domain/auth_service.dart';
import 'package:clinic_go/features/profile/presentation/views/profile_view.dart';
import 'package:clinic_go/features/medication/presentation/views/medications_list_screen.dart';
import 'package:clinic_go/features/medication/services/missed_dose_notification_controller.dart';
import 'package:clinic_go/features/medication/services/dose_scheduling_service.dart';
import 'package:clinic_go/features/medication/models/scheduled_dose.dart';
import 'package:clinic_go/features/medication/data/medication_repository.dart';
import 'package:clinic_go/features/medication/data/dose_log_repository.dart';
import 'package:clinic_go/features/medication/data/calendar_repository.dart';
import 'package:clinic_go/features/medication/presentation/view_models/calendar_view_model.dart';
import 'package:clinic_go/features/medication/presentation/views/daily_doses_screen.dart';
import 'package:clinic_go/features/medication/presentation/views/calendar_screen.dart';
import 'package:clinic_go/features/home/presentation/view_models/home_view_model.dart';
import 'package:clinic_go/core/routing/app_router.dart';
import 'package:intl/intl.dart';

// ── MainScreen ─────────────────────────────────────────────────────────────

class MainScreen extends StatefulWidget {
  const MainScreen({super.key, this.homeViewModel});

  final HomeViewModel? homeViewModel;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 2;
  bool _isSignedIn = false;

  late final CalendarViewModel _calendarViewModel;
  late final HomeViewModel _homeViewModel;

  StreamSubscription<bool>? _authSubscription;

  @override
  void initState() {
    super.initState();

    _calendarViewModel = CalendarViewModel(
      calendarRepository: getIt<CalendarRepository>(),
      medRepository: getIt<MedicationRepository>(),
      schedulingService: getIt<DoseSchedulingService>(),
    );
    _calendarViewModel.loadMonth(DateTime.now());

    _homeViewModel =
        widget.homeViewModel ??
        HomeViewModel(
          repository: getIt<MedicationRepository>(),
          schedulingService: getIt<DoseSchedulingService>(),
          logRepository: getIt<DoseLogRepository>(),
          notificationController: getIt<MissedDoseNotificationController>(),
        );

    if (widget.homeViewModel == null) {
      _homeViewModel.loadNextDose();
    }

    _isSignedIn = getIt<AuthService>().isLoggedIn;

    _authSubscription = getIt<AuthService>().authStateChanges.listen((_) {
      if (!mounted) return;
      // Re-read isLoggedIn synchronously — the stream maps initialSession as
      // false, which would incorrectly hide the navbar on an existing session.
      final signedIn = getIt<AuthService>().isLoggedIn;
      setState(() {
        _isSignedIn = signedIn;
        _currentIndex = signedIn ? 2 : 0;
      });
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _calendarViewModel.dispose();
    if (widget.homeViewModel == null) {
      _homeViewModel.dispose();
    }
    super.dispose();
  }

  void _onDoseLogged() {
    _calendarViewModel.loadMonth(_calendarViewModel.currentMonth);
  }

  void _onMedicationChanged() {
    _homeViewModel.loadNextDose();
    _calendarViewModel.loadMonth(_calendarViewModel.currentMonth);
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      const ProfileView(),
      MedicationsListScreen(onChanged: _onMedicationChanged),
      HomeContent(
        viewModel: _homeViewModel,
        onDoseLogged: _onDoseLogged,
        onGoToMeds: () => setState(() => _currentIndex = 1),
      ),
      CalendarScreen(viewModel: _calendarViewModel),
      const Center(child: Text('Definições')),
    ];

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            IndexedStack(index: _currentIndex, children: screens),
            if (_isSignedIn || _currentIndex != 0)
              FloatingBottomNavBar(
                currentIndex: _currentIndex,
                onTap: (i) => setState(() => _currentIndex = i),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Helpers ─────────────────────────────────────────────────────────────────

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

// ── HomeContent ─────────────────────────────────────────────────────────────

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
              // ── Header bar ──────────────────────────────────────────────
              _HeaderBar(onGoToMeds: widget.onGoToMeds),
              const SizedBox(height: 16),

              // ── Greeting ─────────────────────────────────────────────────
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

              // ── Next dose card ────────────────────────────────────────────
              _NextDoseCard(
                viewModel: _viewModel,
                nextDose: nextDose,
                isOverdue: isOverdue,
                now: now,
                onGoToDailyDoses: () async {
                  final result = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(builder: (_) => const DailyDosesScreen()),
                  );
                  await _onDoseLoggingResult(result);
                },
              ),

              const SizedBox(height: 16),

              // ── Quick actions ─────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _QuickActionBox(
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
                    child: _QuickActionBox(
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

              // ── Today's plan ──────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  const Text(
                    'Plano de hoje',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: AppColors.ink,
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      final result = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (_) => const DailyDosesScreen(),
                        ),
                      );
                      await _onDoseLoggingResult(result);
                    },
                    child: const Text(
                      'Ver tudo',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: AppColors.ink,
                        decoration: TextDecoration.underline,
                        decorationThickness: 2,
                        decorationColor: AppColors.ink,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              if (_viewModel.todayDoses.isEmpty)
                _EmptyPlanCard()
              else
                _TodayPlanCard(entries: _viewModel.todayDoses, now: now),
            ],
          ),
        );
      },
    );
  }
}

// ── _HeaderBar ───────────────────────────────────────────────────────────────

class _HeaderBar extends StatelessWidget {
  const _HeaderBar({this.onGoToMeds});
  final VoidCallback? onGoToMeds;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Logo tile (blue cross)
        GestureDetector(
          onTap: onGoToMeds,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.lemon,
              border: BrutalDecor.border,
              borderRadius: BorderRadius.circular(10),
              boxShadow: BrutalDecor.shadowSm,
            ),
            child: Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CustomPaint(painter: _CrossPainter()),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        const Text(
          'ClinicGO',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
            color: AppColors.ink,
          ),
        ),
      ],
    );
  }
}

class _CrossPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    // vertical bar
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 7 / 18,
          size.height * 2 / 18,
          size.width * 4 / 18,
          size.height * 14 / 18,
        ),
        const Radius.circular(1),
      ),
      paint,
    );
    // horizontal bar
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 2 / 18,
          size.height * 7 / 18,
          size.width * 14 / 18,
          size.height * 4 / 18,
        ),
        const Radius.circular(1),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── _NextDoseCard ─────────────────────────────────────────────────────────────

class _NextDoseCard extends StatelessWidget {
  const _NextDoseCard({
    required this.viewModel,
    required this.nextDose,
    required this.isOverdue,
    required this.now,
    required this.onGoToDailyDoses,
  });

  final HomeViewModel viewModel;
  final ScheduledDose? nextDose;
  final bool isOverdue;
  final DateTime now;
  final VoidCallback onGoToDailyDoses;

  @override
  Widget build(BuildContext context) {
    if (nextDose == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.mint,
          border: BrutalDecor.border,
          borderRadius: BorderRadius.circular(22),
          boxShadow: BrutalDecor.shadow,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.paper,
                border: BrutalDecor.border,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.check, color: AppColors.ink, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                viewModel.hadDosesToday
                    ? 'Tudo feito por hoje!'
                    : 'Sem doses agendadas.',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final overdueMinutes = isOverdue
        ? now.difference(nextDose!.scheduledTime).inMinutes
        : 0;
    final timeLabel = DateFormat.Hm().format(nextDose!.scheduledTime);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.coral,
        border: BrutalDecor.border,
        borderRadius: BorderRadius.circular(22),
        boxShadow: BrutalDecor.shadow,
      ),
      child: Stack(
        children: [
          // Overdue badge (top-right)
          if (isOverdue)
            Positioned(
              top: 14,
              right: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.ink,
                  border: BrutalDecor.border,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'EM ATRASO · ${overdueMinutes}m',
                  style: const TextStyle(
                    color: AppColors.paper,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // "NEXT DOSE" label
                const Text(
                  'PRÓXIMA DOSE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.6,
                    color: AppColors.ink,
                    height: 1,
                  ),
                ),

                const SizedBox(height: 12),

                // Icon + medication info
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.paper,
                        border: BrutalDecor.border,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: SizedBox(
                          width: 30,
                          height: 30,
                          child: CustomPaint(painter: _PillIconPainter()),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 2, right: 80),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${nextDose!.medicationName} ${nextDose!.dosage}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                                color: AppColors.ink,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isOverdue
                                  ? 'Era às $timeLabel'
                                  : 'Agendado às $timeLabel',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.ink.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: _BrutalButton(
                        label: 'Tomar agora',
                        bg: AppColors.ink,
                        fg: AppColors.paper,
                        shadowColor: AppColors.paper,
                        onPressed: viewModel.isLoggingDose
                            ? null
                            : () async {
                                try {
                                  await viewModel.logDose(
                                    dose: nextDose!,
                                    status: DoseLogStatus.taken,
                                  );
                                } catch (_) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Não foi possível guardar. Tente novamente.',
                                      ),
                                    ),
                                  );
                                }
                              },
                        isLoading: viewModel.isLoggingDose,
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 110,
                      child: _BrutalButton(
                        label: 'Saltar',
                        bg: AppColors.paper,
                        fg: AppColors.ink,
                        onPressed: viewModel.isLoggingDose
                            ? null
                            : () async {
                                try {
                                  await viewModel.logDose(
                                    dose: nextDose!,
                                    status: DoseLogStatus.skipped,
                                  );
                                } catch (_) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Não foi possível guardar. Tente novamente.',
                                      ),
                                    ),
                                  );
                                }
                              },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── _QuickActionBox ───────────────────────────────────────────────────────────

class _QuickActionBox extends StatelessWidget {
  const _QuickActionBox({
    required this.bg,
    required this.icon,
    required this.label,
    required this.sub,
    required this.onTap,
  });

  final Color bg;
  final Widget icon;
  final String label;
  final String sub;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
        decoration: BoxDecoration(
          color: bg,
          border: BrutalDecor.border,
          borderRadius: BorderRadius.circular(18),
          boxShadow: BrutalDecor.shadowSm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.paper,
                border: BrutalDecor.border,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(child: icon),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.1,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              sub,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.ink.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── _EmptyPlanCard ────────────────────────────────────────────────────────────

class _EmptyPlanCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: BrutalDecor.border,
        borderRadius: BorderRadius.circular(20),
        boxShadow: BrutalDecor.shadow,
      ),
      child: const Text(
        'Sem doses agendadas para hoje.',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
        ),
      ),
    );
  }
}

// ── _TodayPlanCard ────────────────────────────────────────────────────────────

class _TodayPlanCard extends StatelessWidget {
  const _TodayPlanCard({required this.entries, required this.now});
  final List<TodayDoseEntry> entries;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        border: BrutalDecor.border,
        borderRadius: BorderRadius.circular(20),
        boxShadow: BrutalDecor.shadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: List.generate(entries.length, (i) {
          return Container(
            decoration: i == 0
                ? null
                : const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: AppColors.paper, width: 2),
                    ),
                  ),
            child: _TodayPlanRow(entry: entries[i], now: now),
          );
        }),
      ),
    );
  }
}

// ── _TodayPlanRow ─────────────────────────────────────────────────────────────

class _TodayPlanRow extends StatelessWidget {
  const _TodayPlanRow({required this.entry, required this.now});
  final TodayDoseEntry entry;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final timeLabel = DateFormat.Hm().format(entry.dose.scheduledTime);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          // Dot
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: _dotColor(),
              border: BrutalDecor.border,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          // Time
          SizedBox(
            width: 50,
            child: Text(
              timeLabel,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.1,
                color: AppColors.ink,
              ),
            ),
          ),
          // Name
          Expanded(
            child: Text(
              '${entry.dose.medicationName} ${entry.dose.dosage}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.1,
                color: AppColors.ink,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          // Badge
          _statusBadge(),
        ],
      ),
    );
  }

  Color _dotColor() {
    if (!entry.isPending) return AppColors.mint;
    if (entry.isOverdue) return AppColors.coral;
    return AppColors.lemon;
  }

  Widget _statusBadge() {
    final Color bg;
    final String label;

    if (!entry.isPending) {
      bg = AppColors.mint;
      label = 'FEITO';
    } else if (entry.isOverdue) {
      bg = AppColors.coral;
      label = 'EM ATRASO';
    } else {
      final minutes = entry.dose.scheduledTime.difference(now).inMinutes;
      if (minutes < 60) {
        bg = AppColors.lemon;
        label = 'EM ${minutes}m';
      } else {
        final hours = minutes ~/ 60;
        if (hours >= 20) {
          bg = AppColors.card;
          label = 'ESTA NOITE';
        } else {
          bg = AppColors.lemon;
          label = 'EM ${hours}h';
        }
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        border: BrutalDecor.border,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.0,
          color: AppColors.ink,
        ),
      ),
    );
  }
}

// ── _BrutalButton ─────────────────────────────────────────────────────────────

class _BrutalButton extends StatelessWidget {
  const _BrutalButton({
    required this.label,
    required this.bg,
    required this.fg,
    this.shadowColor,
    this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final Color bg;
  final Color fg;
  final Color? shadowColor;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final shadow = shadowColor ?? AppColors.paper;
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: onPressed == null
              ? AppColors.paper.withValues(alpha: 0.3)
              : bg,
          border: BrutalDecor.border,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: shadow, offset: const Offset(3, 3))],
        ),
        child: Center(
          child: isLoading
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: fg),
                )
              : Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.1,
                    color: fg,
                  ),
                ),
        ),
      ),
    );
  }
}

// ── Custom painters ───────────────────────────────────────────────────────────

class _PillIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.coral
      ..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = AppColors.paper
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, size.height * 0.33, size.width, size.height * 0.34),
      Radius.circular(size.height * 0.17),
    );
    canvas.drawRRect(rrect, paint);
    canvas.drawRRect(rrect, stroke);
    // divider line
    canvas.drawLine(
      Offset(size.width / 2, size.height * 0.33),
      Offset(size.width / 2, size.height * 0.67),
      stroke,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
