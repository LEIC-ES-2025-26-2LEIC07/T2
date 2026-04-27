import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:clinic_go/core/color_palette/app_colors.dart';
import 'package:clinic_go/core/di/service_locator.dart';
import 'package:clinic_go/core/widgets/app_background.dart';
import 'package:clinic_go/core/widgets/floating_bottom_nav_bar.dart';
import 'package:clinic_go/features/auth/domain/auth_service.dart';
import 'package:clinic_go/features/profile/presentation/views/profile_view.dart';
import 'package:clinic_go/features/medication/presentation/views/medications_list_screen.dart';
import 'package:clinic_go/features/medication/data/medication_repository.dart';
import 'package:clinic_go/features/medication/data/dose_log_repository.dart';
import 'package:clinic_go/features/medication/presentation/view_models/daily_doses_view_model.dart';
import 'package:clinic_go/features/medication/services/dose_scheduling_service.dart';
import 'package:clinic_go/features/home/presentation/view_models/home_view_model.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key, this.homeViewModel});

  final HomeViewModel? homeViewModel;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 2; 

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
  const HomeContent({super.key, this.viewModel, this.dosesViewModel});

  final HomeViewModel? viewModel;
  final DailyDosesViewModel? dosesViewModel;

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  late final DailyDosesViewModel _dosesViewModel;

  @override
  void initState() {
    super.initState();
    _dosesViewModel = widget.dosesViewModel ??
        DailyDosesViewModel(
          repository: getIt<MedicationRepository>(),
          schedulingService: getIt<DoseSchedulingService>(),
          logRepository: getIt<DoseLogRepository>(),
        );
    _dosesViewModel.loadTodayDoses();
  }

  @override
  void dispose() {
    _dosesViewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = getIt<AuthService>();
    final userEmail = authService.currentUserEmail ?? '';
    final userName = userEmail.contains('@')
        ? userEmail.split('@').first
        : (userEmail.isEmpty ? 'there' : userEmail);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 90),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HomeHeader(userName: userName),
            const SizedBox(height: 20),
            const _DateNavBar(),
            const SizedBox(height: 8),
            Text(
              DateFormat('EEEE, MMMM d').format(DateTime.now()),
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: AnimatedBuilder(
                animation: _dosesViewModel,
                builder: (context, _) {
                  if (_dosesViewModel.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (_dosesViewModel.doses.isEmpty) {
                    return const Center(
                      child: Text(
                        'No doses scheduled for today.',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    itemCount: _dosesViewModel.doses.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, i) =>
                        _MedCard(item: _dosesViewModel.doses[i]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Welcome header ───────────────────────────────────────────────────

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.userName});
  final String userName;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome Back $userName',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.brandBlue,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Here's your medication schedule for today.",
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}

// ── Date navigation bar ──────────────────────────────────────────────

class _DateNavBar extends StatelessWidget {
  const _DateNavBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        OutlinedButton(
          onPressed: () {},
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.black54,
            side: const BorderSide(color: Colors.black26),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Prev'),
        ),
        const SizedBox(width: 12),
        FilledButton(
          onPressed: () {},
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.brandBlue,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Today'),
        ),
        const SizedBox(width: 12),
        OutlinedButton(
          onPressed: () {},
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.black54,
            side: const BorderSide(color: Colors.black26),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Next'),
        ),
      ],
    );
  }
}

// ── Medication card widget ───────────────────────────────────────────

class _MedCard extends StatelessWidget {
  const _MedCard({required this.item});
  final DoseItem item;

  @override
  Widget build(BuildContext context) {
    final med = item.medication;
    final indicatorColor = med?.color ?? AppColors.brandBlue;
    final timeLabel =
        TimeOfDay.fromDateTime(item.dose.scheduledTime).format(context);

    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left content area
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Blue pill icon circle
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: AppColors.brandBlue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.medication_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Text column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.dose.medicationName,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          if (med?.frequency != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              med!.frequency!,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                          if (med?.notes != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              med!.notes!,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Right panel: color strip + time label
            SizedBox(
              width: 72,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Color strip at top-right
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: indicatorColor,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(12),
                      ),
                    ),
                  ),
                  // Bottom-right: next dose time
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomRight,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 10, bottom: 12),
                        child: Text(
                          'Next: $timeLabel',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.brandBlue,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
