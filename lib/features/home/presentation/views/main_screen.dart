import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:clinic_go/core/di/service_locator.dart';
import 'package:clinic_go/core/widgets/app_background.dart';
import 'package:clinic_go/core/widgets/floating_bottom_nav_bar.dart';
import 'package:clinic_go/features/auth/domain/auth_service.dart';
import 'package:clinic_go/features/profile/presentation/views/profile_view.dart';
import 'package:clinic_go/features/medication/presentation/views/medications_list_screen.dart';
import 'package:clinic_go/features/medication/data/medication_repository.dart';
import 'package:clinic_go/features/medication/data/dose_log_repository.dart';
import 'package:clinic_go/features/medication/models/scheduled_dose.dart';
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
  const HomeContent({super.key, this.viewModel});

  final HomeViewModel? viewModel;

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  late final HomeViewModel _viewModel;
  late final DailyDosesViewModel _dosesViewModel;

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
    _dosesViewModel = DailyDosesViewModel(
      repository: getIt<MedicationRepository>(),
      schedulingService: getIt<DoseSchedulingService>(),
      logRepository: getIt<DoseLogRepository>(),
    );
    if (widget.viewModel == null) _viewModel.loadNextDose();
    _dosesViewModel.loadTodayDoses();
  }

  @override
  void dispose() {
    if (widget.viewModel == null) _viewModel.dispose();
    _dosesViewModel.dispose();
    super.dispose();
  }

  Future<void> _logDose(ScheduledDose dose, DoseLogStatus status) async {
    try {
      await _dosesViewModel.logDose(dose: dose, status: status);
      _viewModel.loadNextDose();
    } catch (e) {
      if (!mounted) return;
      final message = e is SocketException
          ? 'Network error. Please check your connection and try again.'
          : 'We could not save this dose right now. Please try again.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 90),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ClinicGO',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4E84E5),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: AnimatedBuilder(
                animation: _dosesViewModel,
                builder: (context, _) => _TodaysDosesSection(
                  doses: _dosesViewModel.doses,
                  isLoading: _dosesViewModel.isLoading,
                  onLog: _logDose,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Today's Doses section ───────────────────────────────────────────

class _TodaysDosesSection extends StatelessWidget {
  const _TodaysDosesSection({
    required this.doses,
    required this.isLoading,
    required this.onLog,
  });

  final List<DoseItem> doses;
  final bool isLoading;
  final Future<void> Function(ScheduledDose dose, DoseLogStatus status) onLog;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const Text(
              "Today's Doses",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4E84E5),
              ),
            ),
            if (isLoading) ...[
              const SizedBox(width: 12),
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        if (!isLoading && doses.isEmpty)
          const Text(
            'No doses scheduled for today.',
            style: TextStyle(color: Colors.black45, fontSize: 14),
          )
        else
          ...doses.map(
            (item) => _DoseRow(
              item: item,
              onTake: () => onLog(item.dose, DoseLogStatus.taken),
              onSkip: () => onLog(item.dose, DoseLogStatus.skipped),
            ),
          ),
        const Divider(height: 24),
      ],
    );
  }
}

class _DoseRow extends StatelessWidget {
  const _DoseRow({
    required this.item,
    required this.onTake,
    required this.onSkip,
  });

  final DoseItem item;
  final VoidCallback onTake;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final time = TimeOfDay.fromDateTime(item.dose.scheduledTime).format(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: Text(
              time,
              style: const TextStyle(
                color: Colors.black45,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.dose.medicationName,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                if (item.dose.dosage.isNotEmpty)
                  Text(
                    item.dose.dosage,
                    style: const TextStyle(fontSize: 12, color: Colors.black45),
                  ),
              ],
            ),
          ),
          if (item.isSubmitting)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else if (item.status != null)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  item.status == DoseLogStatus.taken
                      ? Icons.check_circle_outline
                      : Icons.block,
                  size: 18,
                  color: item.status == DoseLogStatus.taken
                      ? Colors.green
                      : Colors.orange,
                ),
                const SizedBox(width: 4),
                Text(
                  item.status == DoseLogStatus.taken ? 'Taken' : 'Skipped',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: item.status == DoseLogStatus.taken
                        ? Colors.green
                        : Colors.orange,
                  ),
                ),
              ],
            )
          else
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FilledButton(
                  onPressed: onTake,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: const TextStyle(fontSize: 13),
                  ),
                  child: const Text('Take'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: onSkip,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: const TextStyle(fontSize: 13),
                  ),
                  child: const Text('Skip'),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
