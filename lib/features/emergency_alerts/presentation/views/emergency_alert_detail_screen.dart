import 'dart:async';

import 'package:flutter/material.dart';

import 'package:clinic_go/core/di/service_locator.dart';
import 'package:clinic_go/core/themes/app_colors.dart';
import '../view_models/emergency_alert_controller.dart';

class EmergencyAlertDetailScreen extends StatefulWidget {
  const EmergencyAlertDetailScreen({super.key, required this.alertId});

  final String alertId;

  @override
  State<EmergencyAlertDetailScreen> createState() =>
      _EmergencyAlertDetailScreenState();
}

class _EmergencyAlertDetailScreenState
    extends State<EmergencyAlertDetailScreen> {
  late final EmergencyAlertController _controller;

  @override
  void initState() {
    super.initState();
    _controller = getIt<EmergencyAlertController>()..addListener(_onChanged);
    unawaited(_controller.loadAlert(widget.alertId));
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final alert = _controller.alertById(widget.alertId);

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        backgroundColor: AppColors.dangerRed,
        foregroundColor: Colors.white,
        title: const Text('Emergency Alert'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: alert == null
            ? const Center(
                child: Text(
                  'This alert has already been acknowledged or is no longer available.',
                  textAlign: TextAlign.center,
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BrutalDecor.box(
                      color: AppColors.errorBgLight,
                      radius: 12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.emergency,
                          color: AppColors.dangerRed,
                          size: 38,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          alert.title,
                          style: const TextStyle(
                            color: AppColors.ink,
                            fontWeight: FontWeight.w900,
                            fontSize: 24,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          alert.message,
                          style: const TextStyle(
                            color: AppColors.ink,
                            fontSize: 16,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Raised ${_formatTime(alert.createdAt)}',
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    height: 52,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.dangerRed,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        unawaited(_controller.acknowledge(alert.id));
                        Navigator.of(context).maybePop();
                      },
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text(
                        'Acknowledge Alert',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  String _formatTime(DateTime value) {
    final local = value.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '${local.day}/${local.month}/${local.year} at $hour:$minute';
  }
}
