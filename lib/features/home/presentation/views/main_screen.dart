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
import 'package:clinic_go/features/home/presentation/view_models/home_view_model.dart';
import 'package:intl/intl.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key, this.homeViewModel});

  final HomeViewModel? homeViewModel;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 2; // Home as default

  StreamSubscription<bool>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _authSubscription = getIt<AuthService>().authStateChanges.listen((
      isSignedIn,
    ) {
      if (!mounted) return;
      if (isSignedIn) {
        setState(() => _currentIndex = 2); // jump to Home on login
      } else {
        setState(() => _currentIndex = 0); // return to Profile on logout
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      const ProfileView(),
      const MedicationsListScreen(),
      HomeContent(viewModel: widget.homeViewModel),
      const Center(child: Text('Calendário')),
      const Center(child: Text('Definições')),
    ];

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            IndexedStack(index: _currentIndex, children: screens),

            // Search bar pinned to top on the Home tab only
            if (_currentIndex == 2)
              const SafeArea(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 16.0,
                  ),
                  child: CustomSearchBar(),
                ),
              ),

            FloatingBottomNavBar(
              currentIndex: _currentIndex,
              onTap: (index) => setState(() => _currentIndex = index),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeContent extends StatefulWidget {
  const HomeContent({super.key, this.viewModel});

  final HomeViewModel? viewModel;

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

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        if (_viewModel.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final nextDose = _viewModel.nextDose;
        final isOverdue = _viewModel.isOverdue;
        final scheduledTimeLabel = nextDose != null
            ? DateFormat.Hm().format(nextDose.scheduledTime)
            : '';
        final statusColor = isOverdue
            ? const Color(0xFFE53935)
            : Colors.black87;

        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 120),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Welcome to ClinicGO!'),
                const SizedBox(height: 24),
                if (nextDose == null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.88),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: const Text(
                      'No upcoming doses. Good job!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
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
                        FilledButton(
                          onPressed: () async {
                            final result = await Navigator.of(context).pushNamed(
                              MissedDoseNotificationController.buildDoseLoggingRoute(
                                nextDose,
                                isOverdue: isOverdue,
                              ),
                            );
                            if (result == true) {
                              _viewModel.loadNextDose(); // refresh on success
                            }
                          },
                          style: isOverdue
                              ? FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFFE53935),
                                )
                              : null,
                          child: Text(
                            isOverdue ? 'Log Overdue Dose' : 'Log Dose',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    // Logic to simulate opening an overdue dose for testing
                    // Matches Lisbonipril • 10mg demo data in notification_flow_test
                    Navigator.of(context).pushNamed(
                      MissedDoseNotificationController.buildDoseLoggingRoute(
                        ScheduledDose(
                          id: 'demo-overdue-123',
                          medicationId: 'med-123',
                          medicationName: 'Lisinopril',
                          dosage: '10mg',
                          scheduledTime: DateTime(
                            2026,
                            1,
                            1,
                          ), // Date is ignored for overdue check usually
                        ),
                        isOverdue: true,
                      ),
                    );
                  },
                  child: const Text('Open overdue dose'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
