import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:clinic_go/ui/auth/view_models/auth_view_model.dart';
import 'package:clinic_go/domain/models/user_model.dart';

/// Displays the authenticated user's profile information.
///
/// Reads user data from [AuthViewModel] and exposes a sign-out action.
class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();
    final user = vm.user;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 90),
          decoration: BoxDecoration(
            color: const Color(0xFFE2E2D9),
            borderRadius: BorderRadius.circular(50),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ── Avatar ─────────────────────────────────────────────────
                _Avatar(user: user),

                const SizedBox(height: 16),

                // ── Display name / email ────────────────────────────────────
                Text(
                  user?.displayLabel ?? 'Utilizador',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                if (user?.email != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    user!.email!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF808080),
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                // ── Info cards ──────────────────────────────────────────────
                if (user != null) ...[
                  _InfoCard(
                    icon: Icons.person_outline,
                    label: 'Nome completo',
                    value: user.fullName ?? '—',
                  ),
                  const SizedBox(height: 12),
                  _InfoCard(
                    icon: Icons.cake_outlined,
                    label: 'Data de nascimento',
                    value: user.dateOfBirth ?? '—',
                  ),
                  const SizedBox(height: 12),
                  _InfoCard(
                    icon: Icons.phone_outlined,
                    label: 'Telemóvel',
                    value: user.phone ?? '—',
                  ),
                ],

                const SizedBox(height: 36),

                // ── Sign out ────────────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    key: const Key('signOutButton'),
                    onPressed: vm.status == AuthStatus.loading
                        ? null
                        : () => vm.signOut(),
                    icon: const Icon(Icons.logout, size: 18),
                    label: const Text('Terminar sessão'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black,
                      side: const BorderSide(color: Colors.black26),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final UserModel? user;
  const _Avatar({this.user});

  @override
  Widget build(BuildContext context) {
    final initials = user != null
        ? (user!.displayLabel.isNotEmpty
              ? user!.displayLabel[0].toUpperCase()
              : '?')
        : '?';

    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        color: Colors.black,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            fontSize: 32,
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF606060)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF909090),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
