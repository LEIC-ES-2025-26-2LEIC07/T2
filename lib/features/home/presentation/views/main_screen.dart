import 'dart:async';

import 'package:flutter/material.dart';
import 'package:clinic_go/core/di/service_locator.dart';
import 'package:clinic_go/core/widgets/app_background.dart';
import 'package:clinic_go/core/widgets/custom_search_bar.dart';
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

class MainScreen extends StatefulWidget {
  const MainScreen({super.key, this.homeViewModel});

  final HomeViewModel? homeViewModel;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 2;

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

    _authSubscription = getIt<AuthService>().authStateChanges.listen((
      isSignedIn,
    ) {
      if (!mounted) return;

      setState(() {
        _currentIndex = isSignedIn ? 2 : 0;
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
      HomeContent(viewModel: _homeViewModel, onDoseLogged: _onDoseLogged),
      CalendarScreen(viewModel: _calendarViewModel),
      const Center(child: Text('Definições')),
    ];

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            IndexedStack(index: _currentIndex, children: screens),

            if (_currentIndex == 2)
              const SafeArea(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: CustomSearchBar(),
                ),
              ),

            FloatingBottomNavBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}

class HomeContent extends StatefulWidget {
  const HomeContent({super.key, this.viewModel, this.onDoseLogged});

  final HomeViewModel? viewModel;
  final VoidCallback? onDoseLogged;

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

        final ScheduledDose? nextDose = _viewModel.nextDose;
        final bool isOverdue = _viewModel.isOverdue;

        final scheduledTimeLabel = nextDose != null
            ? DateFormat.Hm().format(nextDose.scheduledTime)
            : '';

        final statusColor = isOverdue
            ? const Color(0xFFE53935)
            : Colors.black87;

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Welcome to ClinicGO!'),

                const SizedBox(height: 80),

                if (nextDose == null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.88),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Text(
                      _viewModel.hadDosesToday
                          ? 'All done for today!'
                          : 'No upcoming doses.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                else ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.88),
                      borderRadius: BorderRadius.circular(28),
                      border: isOverdue
                          ? Border.all(color: const Color(0xFFFFECEC), width: 2)
                          : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isOverdue ? 'Overdue dose' : 'Upcoming dose',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: isOverdue
                                        ? const Color(0xFFC62828)
                                        : null,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),

                            if (isOverdue)
                              const Icon(
                                Icons.warning_amber_rounded,
                                color: Color(0xFFC62828),
                                size: 20,
                              ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        Text(
                          '${nextDose.medicationName} • ${nextDose.dosage}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          'Scheduled for $scheduledTimeLabel',
                          style: TextStyle(color: statusColor),
                        ),

                        const SizedBox(height: 20),

                        Row(
                          children: [
                            Expanded(
                              child: FilledButton(
                                onPressed: _viewModel.isLoggingDose
                                    ? null
                                    : () async {
                                        try {
                                          await _viewModel.logDose(
                                            dose: nextDose,
                                            status: DoseLogStatus.taken,
                                          );
                                        } catch (_) {
                                          if (!context.mounted) return;

                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Could not save. Please try again.',
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                style: isOverdue
                                    ? FilledButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFFE53935,
                                        ),
                                      )
                                    : null,
                                child: _viewModel.isLoggingDose
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text('Take'),
                              ),
                            ),

                            const SizedBox(width: 12),

                            Expanded(
                              child: OutlinedButton(
                                onPressed: _viewModel.isLoggingDose
                                    ? null
                                    : () async {
                                        try {
                                          await _viewModel.logDose(
                                            dose: nextDose,
                                            status: DoseLogStatus.skipped,
                                          );
                                        } catch (_) {
                                          if (!context.mounted) return;

                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Could not save. Please try again.',
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                child: const Text('Skip'),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        FilledButton(
                          onPressed: () async {
                            final result = await Navigator.of(context)
                                .push<bool>(
                                  MaterialPageRoute(
                                    builder: (_) => const DailyDosesScreen(),
                                  ),
                                );

                            await _onDoseLoggingResult(result);
                          },
                          child: const Text("Today's Schedule"),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pushNamed(AppRouter.logSymptom);
                        },
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text('Log Symptom'),
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(
                            context,
                          ).pushNamed(AppRouter.symptomHistory);
                        },
                        icon: const Icon(Icons.history),
                        label: const Text('Symptom History'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
