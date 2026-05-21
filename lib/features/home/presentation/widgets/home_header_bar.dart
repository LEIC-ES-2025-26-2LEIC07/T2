import 'package:flutter/material.dart';
import 'package:clinic_go/core/widgets/clinic_go_logo.dart';

class HomeHeaderBar extends StatelessWidget {
  const HomeHeaderBar({super.key, this.onGoToMeds});
  final VoidCallback? onGoToMeds;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: onGoToMeds, child: const ClinicGoLogo());
  }
}
