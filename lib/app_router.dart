import 'package:clinic_go/core/providers/supabase_providers.dart';
import 'package:clinic_go/ui/dashboard/views/dashboard_home_view.dart';
import 'package:clinic_go/ui/dashboard/views/dashboard_shell.dart';
import 'package:clinic_go/ui/favorites/views/favorites_view.dart';
import 'package:clinic_go/ui/placeholders/views/placeholder_view.dart';
import 'package:clinic_go/ui/profile/views/profile_view.dart';
import 'package:clinic_go/ui/symptoms/views/log_symptom_screen.dart';
import 'package:clinic_go/ui/symptoms/views/symptom_history_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/dashboard',
    refreshListenable: GoRouterRefreshStream(authRepository.authStateChanges),
    redirect: (context, state) {
      final isProtected =
          state.matchedLocation == '/dashboard/log-symptom' ||
          state.matchedLocation == '/dashboard/symptom-history';
      final isSignedIn = authRepository.currentUser != null;

      if (isProtected && !isSignedIn) {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return DashboardShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileView(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/favorites',
                builder: (context, state) => const FavoritesView(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (context, state) => const DashboardHomeView(),
                routes: [
                  GoRoute(
                    path: 'log-symptom',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const LogSymptomScreen(),
                  ),
                  GoRoute(
                    path: 'symptom-history',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const SymptomHistoryScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/calendar',
                builder: (context, state) => const PlaceholderView(
                  title: 'Calendar',
                  description:
                      'Appointments and care schedule will appear here.',
                  icon: Icons.calendar_month_outlined,
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const PlaceholderView(
                  title: 'Settings',
                  description: 'Preferences and account controls live here.',
                  icon: Icons.settings_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
