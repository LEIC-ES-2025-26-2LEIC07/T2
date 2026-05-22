import 'package:flutter/material.dart';
import 'package:clinic_go/core/di/service_locator.dart';
import 'package:clinic_go/core/themes/app_colors.dart';
import 'package:clinic_go/core/widgets/clinic_go_logo.dart';
import 'package:clinic_go/features/auth/domain/auth_service.dart';
import 'package:clinic_go/features/settings/presentation/views/health_conditions_screen.dart';
import 'package:clinic_go/features/settings/presentation/views/routine_schedules_screen.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  bool _notificationsEnabled = true;
  bool _snoozeEnabled = true;
  bool _syncHealthEnabled = true;

  List<String> _conditions = [];
  List<String> _allergies = [];
  List<TimeOfDay> _schedules = [];

  String? get _healthSubtitle {
    final all = [..._conditions, ..._allergies];
    if (all.isEmpty) return null;
    if (all.length <= 3) return all.join(' · ');
    return '${all.take(2).join(' · ')} +${all.length - 2}';
  }

  String? get _schedulesSubtitle {
    if (_schedules.isEmpty) return null;
    String fmt(TimeOfDay t) =>
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    if (_schedules.length <= 3) return _schedules.map(fmt).join(' · ');
    return '${_schedules.take(2).map(fmt).join(' · ')} +${_schedules.length - 2}';
  }

  Future<void> _openRoutineSchedules() async {
    final result = await Navigator.of(context).push<List<TimeOfDay>>(
      MaterialPageRoute(
        builder: (_) => RoutineSchedulesScreen(schedules: _schedules),
      ),
    );
    if (result != null) {
      setState(() => _schedules = result);
    }
  }

  Future<void> _openHealthConditions() async {
    final result = await Navigator.of(context).push<HealthData>(
      MaterialPageRoute(
        builder: (_) => HealthConditionsScreen(
          conditions: _conditions,
          allergies: _allergies,
        ),
      ),
    );
    if (result != null) {
      setState(() {
        _conditions = result.conditions;
        _allergies = result.allergies;
      });
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.ink, width: 2),
        ),
        title: const Text(
          'Terminar sessão',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 17,
            color: AppColors.ink,
          ),
        ),
        content: const Text(
          'Tens a certeza que queres sair?',
          style: TextStyle(fontSize: 14, color: AppColors.ink),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Cancelar',
              style: TextStyle(
                color: AppColors.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Sair',
              style: TextStyle(
                color: AppColors.coral,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await getIt<AuthService>().signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ClinicGoLogo(),
            const SizedBox(height: 22),
            const Text(
              'Definições',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: AppColors.ink,
              ),
            ),
            const Text(
              'Lembretes, conta e privacidade',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.muted,
                letterSpacing: 0.1,
              ),
            ),
            const SizedBox(height: 28),
            _SectionHeader(label: 'Lembretes'),
            const SizedBox(height: 10),
            _SettingsCard(
              children: [
                _ToggleRow(
                  iconBg: AppColors.coral,
                  icon: Icons.notifications_outlined,
                  title: 'Notificações',
                  subtitle: 'Som, vibração, ecrã',
                  value: _notificationsEnabled,
                  onChanged: (v) => setState(() => _notificationsEnabled = v),
                ),
                const _RowDivider(),
                _ToggleRow(
                  iconBg: AppColors.coral,
                  icon: Icons.snooze_outlined,
                  title: 'Repetir em atraso',
                  subtitle: 'A cada 10 minutos até tomar',
                  value: _snoozeEnabled,
                  onChanged: (v) => setState(() => _snoozeEnabled = v),
                ),
                const _RowDivider(),
                _ChevronRow(
                  iconBg: AppColors.lemon,
                  icon: Icons.access_time_outlined,
                  title: 'Horários habituais',
                  subtitle: _schedulesSubtitle,
                  onTap: _openRoutineSchedules,
                ),
              ],
            ),
            const SizedBox(height: 24),
            _SectionHeader(label: 'Saúde'),
            const SizedBox(height: 10),
            _SettingsCard(
              children: [
                _ChevronRow(
                  iconBg: AppColors.mint,
                  icon: Icons.favorite_border,
                  title: 'Condições e alergias',
                  subtitle: _healthSubtitle,
                  onTap: _openHealthConditions,
                ),
                const _RowDivider(),
                _ToggleRow(
                  iconBg: AppColors.lemon,
                  icon: Icons.sync_outlined,
                  title: 'Sincronizar com Saúde',
                  subtitle: 'Apple Health · Ligado',
                  value: _syncHealthEnabled,
                  onChanged: (v) => setState(() => _syncHealthEnabled = v),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _SectionHeader(label: 'Conta'),
            const SizedBox(height: 10),
            _SettingsCard(
              children: [
                _ChevronRow(
                  iconBg: AppColors.rose,
                  icon: Icons.lock_outline,
                  title: 'Privacidade',
                  subtitle: 'Gestão de dados pessoais',
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 24),
            _LogoutButton(onPressed: _handleLogout),
          ],
        ),
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
        color: AppColors.ink,
      ),
    );
  }
}

// ── Card container ────────────────────────────────────────────────────────────

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        border: BrutalDecor.border,
        borderRadius: BorderRadius.circular(16),
        boxShadow: BrutalDecor.shadow,
      ),
      child: Column(children: children),
    );
  }
}

// ── Row divider ───────────────────────────────────────────────────────────────

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      thickness: 1.5,
      color: AppColors.paper,
      indent: 66,
    );
  }
}

// ── Icon box ──────────────────────────────────────────────────────────────────

class _IconBox extends StatelessWidget {
  const _IconBox({required this.color, required this.icon});
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: const Border.fromBorderSide(
          BorderSide(color: AppColors.ink, width: 1.5),
        ),
      ),
      child: Icon(icon, color: AppColors.card, size: 20),
    );
  }
}

// ── Toggle row ────────────────────────────────────────────────────────────────

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.iconBg,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final Color iconBg;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          _IconBox(color: iconBg, icon: icon),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: const Color(0xFF34C759),
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: const Color(0xFFDDE3EA),
            trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
          ),
        ],
      ),
    );
  }
}

// ── Chevron row ───────────────────────────────────────────────────────────────

class _ChevronRow extends StatelessWidget {
  const _ChevronRow({
    required this.iconBg,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  final Color iconBg;
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            _IconBox(color: iconBg, icon: icon),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.muted, size: 22),
          ],
        ),
      ),
    );
  }
}

// ── Logout button ─────────────────────────────────────────────────────────────

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: AppColors.errorBgLight,
          border: const Border.fromBorderSide(
            BorderSide(color: AppColors.coral, width: 2),
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(color: AppColors.coral, offset: Offset(3, 3)),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, color: AppColors.coral, size: 18),
            SizedBox(width: 8),
            Text(
              'Terminar sessão',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.coral,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
