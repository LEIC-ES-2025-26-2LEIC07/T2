import 'package:clinic_go/ui/background/view_models/app_background.dart';
import 'package:clinic_go/ui/common/widgets/floating_bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DashboardShell extends StatelessWidget {
  const DashboardShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          AppBackground(child: navigationShell),
          FloatingBottomNavBar(
            currentIndex: navigationShell.currentIndex,
            onTap: (index) => navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            ),
          ),
        ],
      ),
      floatingActionButton: navigationShell.currentIndex == 2
          ? FloatingActionButton.extended(
              onPressed: () {
                context.push('/dashboard/log-symptom');
              },
              icon: const Icon(Icons.add),
              label: const Text('Log symptom'),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
