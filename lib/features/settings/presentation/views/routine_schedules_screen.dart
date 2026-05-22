import 'package:flutter/material.dart';
import 'package:clinic_go/core/themes/app_colors.dart';

class RoutineSchedulesScreen extends StatefulWidget {
  const RoutineSchedulesScreen({super.key, required this.schedules});

  final List<TimeOfDay> schedules;

  @override
  State<RoutineSchedulesScreen> createState() => _RoutineSchedulesScreenState();
}

class _RoutineSchedulesScreenState extends State<RoutineSchedulesScreen> {
  late final List<TimeOfDay> _schedules;

  @override
  void initState() {
    super.initState();
    _schedules = List.from(widget.schedules)..sort(_compareTime);
  }

  int _compareTime(TimeOfDay a, TimeOfDay b) =>
      (a.hour * 60 + a.minute) - (b.hour * 60 + b.minute);

  String _format(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  void _pop() => Navigator.of(context).pop(List<TimeOfDay>.from(_schedules));

  Future<void> _addSchedule() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(
            primary: AppColors.lemon,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    final alreadyExists = _schedules.any(
      (t) => t.hour == picked.hour && t.minute == picked.minute,
    );
    if (alreadyExists) return;
    setState(() {
      _schedules
        ..add(picked)
        ..sort(_compareTime);
    });
  }

  void _remove(int index) => setState(() => _schedules.removeAt(index));

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _pop();
      },
      child: Scaffold(
        backgroundColor: AppColors.paper,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: _pop,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          border: BrutalDecor.border,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: BrutalDecor.shadowSm,
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: AppColors.ink,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Text(
                        'Horários habituais',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _addSchedule,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.lemon,
                          border: BrutalDecor.border,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: BrutalDecor.shadowSm,
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add, color: Colors.white, size: 15),
                            SizedBox(width: 4),
                            Text(
                              'Adicionar',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                child: Text(
                  'Os horários habituais ajudam a sugerir\nmomentos para tomar a medicação.',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.muted,
                    height: 1.5,
                  ),
                ),
              ),
              Expanded(
                child: _schedules.isEmpty
                    ? _EmptyState(onAdd: _addSchedule)
                    : SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            border: BrutalDecor.border,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: BrutalDecor.shadow,
                          ),
                          child: Column(
                            children: [
                              for (int i = 0; i < _schedules.length; i++) ...[
                                if (i > 0)
                                  const Divider(
                                    height: 1,
                                    thickness: 1.5,
                                    color: AppColors.paper,
                                    indent: 66,
                                  ),
                                _ScheduleRow(
                                  time: _format(_schedules[i]),
                                  onRemove: () => _remove(i),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.lemon.withValues(alpha: 0.12),
                border: BrutalDecor.border,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.access_time_outlined,
                color: AppColors.lemon,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Nenhum horário configurado',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Adiciona os horários em que costumas\ntomar a tua medicação.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.muted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: onAdd,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.lemon,
                  border: BrutalDecor.border,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: BrutalDecor.shadow,
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, color: Colors.white, size: 18),
                    SizedBox(width: 6),
                    Text(
                      'Adicionar horário',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Schedule row ──────────────────────────────────────────────────────────────

class _ScheduleRow extends StatelessWidget {
  const _ScheduleRow({required this.time, required this.onRemove});

  final String time;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.lemon,
              borderRadius: BorderRadius.circular(12),
              border: const Border.fromBorderSide(
                BorderSide(color: AppColors.ink, width: 1.5),
              ),
            ),
            child: const Icon(
              Icons.access_time_outlined,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              time,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
                letterSpacing: 0.5,
              ),
            ),
          ),
          GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: AppColors.errorBgLight,
                borderRadius: BorderRadius.circular(8),
                border: const Border.fromBorderSide(
                  BorderSide(color: AppColors.coral, width: 1.5),
                ),
              ),
              child: const Icon(Icons.close, color: AppColors.coral, size: 16),
            ),
          ),
        ],
      ),
    );
  }
}
