import 'dart:async';

import 'package:flutter/material.dart';
import 'package:clinic_go/core/di/service_locator.dart';
import 'package:clinic_go/core/widgets/app_background.dart';
import 'package:clinic_go/core/widgets/floating_bottom_nav_bar.dart';
import 'package:clinic_go/features/auth/domain/auth_service.dart';
import 'package:clinic_go/features/profile/presentation/views/profile_view.dart';
import 'package:clinic_go/features/medication/presentation/views/medications_list_screen.dart';
import 'package:clinic_go/features/calendar/data/calendar_repository.dart';
import 'package:clinic_go/features/calendar/presentation/view_models/calendar_view_model.dart';
import 'package:clinic_go/features/calendar/presentation/views/calendar_screen.dart';
import 'package:clinic_go/features/medication/data/medication_repository.dart';
import 'package:clinic_go/features/medication/data/dose_log_repository.dart';
import 'package:clinic_go/features/medication/services/missed_dose_notification_controller.dart';
import 'package:clinic_go/features/medication/services/dose_scheduling_service.dart';
import 'package:clinic_go/features/home/presentation/view_models/home_view_model.dart';
import 'package:clinic_go/features/home/presentation/views/home_content.dart';

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
