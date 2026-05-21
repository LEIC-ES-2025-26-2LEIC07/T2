import 'package:flutter/material.dart';
import 'package:clinic_go/core/di/service_locator.dart';
import 'package:clinic_go/core/routing/app_router.dart';
import 'package:clinic_go/core/widgets/app_background.dart';
import 'package:clinic_go/core/widgets/clinic_go_logo.dart';
import 'package:clinic_go/features/auth/domain/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1500), _navigate);
  }

  void _navigate() {
    if (!mounted) return;
    final isLoggedIn = getIt<AuthService>().isLoggedIn;
    Navigator.of(context).pushNamedAndRemoveUntil(
      isLoggedIn ? AppRouter.home : AppRouter.login,
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      wallpaper: 'assets/images/wallpaper-sky.png',
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Transform.scale(scale: 1.8, child: const ClinicGoLogo()),
        ),
      ),
    );
  }
}
