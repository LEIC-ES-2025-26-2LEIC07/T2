import 'dart:async';

import 'package:flutter/material.dart';
import 'package:clinic_go/core/di/service_locator.dart';
import 'package:clinic_go/core/widgets/app_background.dart';
import 'package:clinic_go/core/widgets/custom_search_bar.dart';
import 'package:clinic_go/core/widgets/floating_bottom_nav_bar.dart';
import 'package:clinic_go/features/auth/domain/auth_service.dart';
import 'package:clinic_go/features/profile/presentation/views/profile_view.dart';
import 'package:clinic_go/features/favorites/presentation/views/favorites_view.dart';
import 'package:clinic_go/features/medication/models/scheduled_dose.dart';
import 'package:clinic_go/features/medication/services/missed_dose_notification_controller.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 2; // Home as default

  StreamSubscription<bool>? _authSubscription;

  final List<Widget> _pages = [
    const ProfileView(),
    const FavoritesView(),
    const HomeContent(),
    const Center(child: Text('Calendário')),
    const Center(child: Text('Definições')),
  ];

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
    return Scaffold(
      body: Stack(
        children: [
          AppBackground(
            child: _currentIndex == 2
                ? const HomeContent()
                : _pages[_currentIndex],
          ),

          // Search bar pinned to top on the Home tab only
          if (_currentIndex == 2)
            const SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: CustomSearchBar(),
              ),
            ),

          FloatingBottomNavBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
          ),
        ],
      ),
    );
  }
}

class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  ScheduledDose get _demoDose => ScheduledDose(
    id: 'demo-dose-08-00',
    medicationId: 'med-1',
    medicationName: 'Lisinopril',
    dosage: '10 mg',
    scheduledTime: DateTime(2026, 4, 16, 8),
  );

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 120),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Bem-vindo à ClinicGO!'),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Upcoming dose',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text('${_demoDose.medicationName} • ${_demoDose.dosage}'),
                  const SizedBox(height: 4),
                  const Text('Scheduled for 08:00'),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      Navigator.of(context).pushNamed(
                        MissedDoseNotificationController.buildDoseLoggingRoute(
                          _demoDose,
                          isOverdue: true,
                        ),
                      );
                    },
                    child: const Text('Open overdue dose'),
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
