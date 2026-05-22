import 'package:flutter/material.dart';
import 'package:clinic_go/core/themes/app_colors.dart';
import 'package:clinic_go/features/auth/presentation/views/sign_up_sheet.dart';
import 'package:clinic_go/features/profile/presentation/view_models/profile_view_model.dart';

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts[0].isEmpty) return '?';
  if (parts.length == 1) return parts[0][0].toUpperCase();
  return '${parts[0][0]}${parts.last[0]}'.toUpperCase();
}

class ProfileStatusMessage extends StatelessWidget {
  const ProfileStatusMessage({
    super.key,
    required this.errorMessage,
    required this.infoMessage,
  });

  final String? errorMessage;
  final String? infoMessage;

  @override
  Widget build(BuildContext context) {
    if (errorMessage == null && infoMessage == null) {
      return const SizedBox(height: 20);
    }

    final isError = errorMessage != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isError ? AppColors.errorBgLight : AppColors.successBgLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        errorMessage ?? infoMessage ?? '',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: isError ? AppColors.errorTextDark : AppColors.successTextDark,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class ProfileLoginTextField extends StatelessWidget {
  const ProfileLoginTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.keyboardType,
    this.obscureText = false,
  });

  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          color: AppColors.muted,
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: AppColors.card,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.rose),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.rose),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primaryColor),
        ),
      ),
    );
  }
}

class ProfileLoginDivider extends StatelessWidget {
  const ProfileLoginDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: Divider(color: AppColors.muted, thickness: 1.2)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'Continue with',
            style: TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(child: Divider(color: AppColors.muted, thickness: 1.2)),
      ],
    );
  }
}

class ProfileForgotPasswordText extends StatelessWidget {
  const ProfileForgotPasswordText({
    super.key,
    required this.isLoading,
    required this.onPressed,
  });

  final bool isLoading;
  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: isLoading ? null : onPressed,
      child: const Text(
        'Forgot password',
        style: TextStyle(
          color: AppColors.muted,
          decoration: TextDecoration.underline,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class ProfileContinueButton extends StatelessWidget {
  const ProfileContinueButton({
    super.key,
    required this.isLoading,
    required this.onPressed,
  });

  final bool isLoading;
  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 195,
      height: 64,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primaryColor,
          disabledForegroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.2,
                ),
              )
            : const Text(
                'Continue',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }
}

class ProfileLoginForm extends StatelessWidget {
  const ProfileLoginForm({
    super.key,
    required this.viewModel,
    required this.emailController,
    required this.passwordController,
    required this.onLoginPressed,
    required this.onForgotPasswordPressed,
  });

  final ProfileViewModel viewModel;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final Future<void> Function() onLoginPressed;
  final Future<void> Function() onForgotPasswordPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 26),
        const ProfileLoginDivider(),
        const SizedBox(height: 24),
        ProfileLoginTextField(
          controller: emailController,
          hintText: 'Email',
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 12),
        ProfileLoginTextField(
          controller: passwordController,
          hintText: 'Password',
          obscureText: true,
        ),
        const SizedBox(height: 16),
        ProfileStatusMessage(
          errorMessage: viewModel.errorMessage,
          infoMessage: viewModel.infoMessage,
        ),
        const SizedBox(height: 6),
        ProfileForgotPasswordText(
          isLoading: viewModel.isLoading,
          onPressed: onForgotPasswordPressed,
        ),
        const SizedBox(height: 28),
        ProfileContinueButton(
          isLoading: viewModel.isLoading,
          onPressed: onLoginPressed,
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: viewModel.isLoading
              ? null
              : () => SignUpSheet.show(context),
          child: const Text.rich(
            TextSpan(
              text: "Don't have an account? ",
              style: TextStyle(color: AppColors.muted),
              children: [
                TextSpan(
                  text: 'Create one now',
                  style: TextStyle(
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.name, this.onEditPressed});

  final String name;
  final VoidCallback? onEditPressed;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.sky,
            border: Border.all(color: AppColors.ink, width: 2.5),
          ),
          child: Center(
            child: Text(
              _initials(name),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
          ),
        ),
        Positioned(
          right: -2,
          bottom: -2,
          child: GestureDetector(
            onTap: onEditPressed,
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.lemon,
                border: Border.all(color: AppColors.ink, width: 1.5),
              ),
              child: const Icon(Icons.edit, size: 13, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileInfoRow extends StatelessWidget {
  const _ProfileInfoRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconBg,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color iconBg;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: BrutalDecor.border,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.ink, width: 1.5),
            ),
            child: Icon(icon, size: 20, color: AppColors.ink),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.muted,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value.isEmpty ? '-' : value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BrutalButton extends StatelessWidget {
  const _BrutalButton({
    required this.label,
    required this.icon,
    required this.bg,
    required this.fg,
    required this.isLoading,
    this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color bg;
  final Color fg;
  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onPressed,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: bg,
          border: BrutalDecor.border,
          borderRadius: BorderRadius.circular(10),
          boxShadow: BrutalDecor.shadowSm,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(color: fg, strokeWidth: 2),
              )
            else ...[
              Icon(icon, size: 16, color: fg),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: fg,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProfileEditTextField extends StatelessWidget {
  const _ProfileEditTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: AppColors.muted,
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: Icon(icon, color: AppColors.ink, size: 20),
        filled: true,
        fillColor: AppColors.paper,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.ink, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.ink, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.lemon, width: 2),
        ),
      ),
    );
  }
}

class ProfileLoggedInCard extends StatelessWidget {
  const ProfileLoggedInCard({
    super.key,
    required this.viewModel,
    required this.isEditing,
    required this.nameController,
    required this.emailController,
    required this.onEditPressed,
    required this.onCancelPressed,
    required this.onSavePressed,
    required this.onLogoutPressed,
  });

  final ProfileViewModel viewModel;
  final bool isEditing;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final VoidCallback onEditPressed;
  final VoidCallback onCancelPressed;
  final Future<void> Function() onSavePressed;
  final Future<void> Function() onLogoutPressed;

  @override
  Widget build(BuildContext context) {
    final name = nameController.text.trim().isEmpty
        ? 'Utilizador'
        : nameController.text.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BrutalDecor.box(radius: 16),
          child: Column(
            children: [
              _ProfileAvatar(
                name: name,
                onEditPressed: isEditing ? null : onEditPressed,
              ),
              const SizedBox(height: 12),
              Text(
                name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'PACIENTE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.muted,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              if (isEditing) ...[
                _ProfileEditTextField(
                  controller: nameController,
                  label: 'Nome',
                  icon: Icons.person_outline_rounded,
                ),
                const SizedBox(height: 10),
                _ProfileEditTextField(
                  controller: emailController,
                  label: 'Email',
                  icon: Icons.mail_outline_rounded,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
              ],
              ProfileStatusMessage(
                errorMessage: viewModel.errorMessage,
                infoMessage: viewModel.infoMessage,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _BrutalButton(
                      label: isEditing ? 'Guardar' : 'Editar perfil',
                      icon: isEditing
                          ? Icons.check_rounded
                          : Icons.edit_outlined,
                      bg: AppColors.ink,
                      fg: AppColors.card,
                      isLoading: viewModel.isLoading,
                      onPressed: isEditing ? onSavePressed : onEditPressed,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _BrutalButton(
                      label: isEditing ? 'Cancelar' : 'Sair',
                      icon: isEditing
                          ? Icons.close_rounded
                          : Icons.logout_rounded,
                      bg: AppColors.coral,
                      fg: AppColors.card,
                      isLoading: viewModel.isLoading,
                      onPressed: isEditing ? onCancelPressed : onLogoutPressed,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Dados pessoais',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 10),
        _ProfileInfoRow(
          label: 'NOME',
          value: nameController.text.trim(),
          icon: Icons.person_outline_rounded,
          iconBg: AppColors.mint,
        ),
        _ProfileInfoRow(
          label: 'EMAIL',
          value: viewModel.currentUserEmail ?? '',
          icon: Icons.mail_outline_rounded,
          iconBg: AppColors.sky,
        ),
      ],
    );
  }
}
