import 'package:flutter/material.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          margin: const EdgeInsets.only(
            bottom: 90,
          ), // Spacing for the bottom nav bar
          decoration: BoxDecoration(
            color: const Color(0xFFE2E2D9), // Light grey/beige matching mockup
            borderRadius: BorderRadius.circular(50),
          ),
          child: const Padding(
            padding: EdgeInsets.only(top: 40.0),
            child: Align(
              alignment: Alignment.topCenter,
              child: Text(
                'Perfil',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
