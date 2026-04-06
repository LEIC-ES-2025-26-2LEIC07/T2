import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:clinic_go/ui/auth/view_models/auth_view_model.dart';
import 'package:clinic_go/ui/auth/views/login_view.dart';

/// Decides which root widget to render based on [AuthViewModel.status].
///
/// Place this as the `home` of [MaterialApp]. It reacts automatically to
/// Supabase auth-state stream events — no manual navigation needed.
class AuthWrapper extends StatelessWidget {
  /// The app's main shell, shown when authenticated.
  final Widget authenticatedChild;

  const AuthWrapper({super.key, required this.authenticatedChild});

  @override
  Widget build(BuildContext context) {
    final status = context.watch<AuthViewModel>().status;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: switch (status) {
        AuthStatus.initial || AuthStatus.loading => const _SplashScreen(),
        AuthStatus.authenticated => authenticatedChild,
        AuthStatus.unauthenticated || AuthStatus.error => const LoginView(),
      },
    );
  }
}

/// Minimal splash screen shown while the auth state is resolving on cold start.
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF4F4F4),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5),
            SizedBox(height: 20),
            Text(
              'ClinicGO',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.8,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
