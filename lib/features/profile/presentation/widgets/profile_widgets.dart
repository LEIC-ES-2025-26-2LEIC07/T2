import 'package:flutter/material.dart';
import 'package:clinic_go/core/themes/app_colors.dart';
import 'package:clinic_go/features/auth/presentation/views/sign_up_sheet.dart';
import 'package:clinic_go/features/profile/presentation/view_models/profile_view_model.dart';

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
        color: isError ? const Color(0xFFFFECEC) : const Color(0xFFE9F6EC),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        errorMessage ?? infoMessage ?? '',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: isError ? const Color(0xFFC62828) : const Color(0xFF2E7D32),
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
          color: Color(0xFFB0B0B0),
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE4E4E4)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE4E4E4)),
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
        Expanded(child: Divider(color: Color(0xFF8F8F8F), thickness: 1.2)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'Continue with',
            style: TextStyle(
              color: Color(0xFF8F8F8F),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(child: Divider(color: Color(0xFF8F8F8F), thickness: 1.2)),
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
          color: Color(0xFF7F7F7F),
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
              style: TextStyle(color: Color(0xFF8F8F8F)),
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

class ProfileActionButton extends StatelessWidget {
  const ProfileActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.isLoading,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: Icon(icon, size: 18),
        label: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primaryColor,
          disabledForegroundColor: Colors.white,
          elevation: 7,
          shadowColor: Colors.black.withValues(alpha: 0.22),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
        ),
      ),
    );
  }
}

class ProfileFieldData {
  const ProfileFieldData({
    required this.label,
    required this.controller,
    required this.icon,
    this.keyboardType,
    this.readOnly = false,
    this.onTap,
  });

  final String label;
  final TextEditingController controller;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool readOnly;
  final VoidCallback? onTap;
}

class ProfileInfoField extends StatelessWidget {
  const ProfileInfoField({
    super.key,
    required this.data,
    required this.isEditing,
  });

  final ProfileFieldData data;
  final bool isEditing;

  @override
  Widget build(BuildContext context) {
    if (!isEditing) {
      final value = data.controller.text.trim();

      return Column(
        children: [
          Icon(data.icon, color: const Color(0xFFB0B0B0), size: 24),
          const SizedBox(height: 8),
          Text(
            data.label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF4F4F4F),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value.isEmpty ? '-' : value,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF777777),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    return TextField(
      controller: data.controller,
      keyboardType: data.keyboardType,
      readOnly: data.readOnly,
      onTap: data.onTap,
      decoration: InputDecoration(
        labelText: data.label,
        prefixIcon: Icon(data.icon, size: 20),
        filled: true,
        fillColor: const Color(0xFFF7F7F7),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE3E3E3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE3E3E3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primaryColor),
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
    required this.birthDateController,
    required this.phoneController,
    required this.preferencesController,
    required this.onEditPressed,
    required this.onCancelPressed,
    required this.onSavePressed,
    required this.onBirthDatePressed,
    required this.onLogoutPressed,
  });

  final ProfileViewModel viewModel;
  final bool isEditing;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController birthDateController;
  final TextEditingController phoneController;
  final TextEditingController preferencesController;
  final VoidCallback onEditPressed;
  final VoidCallback onCancelPressed;
  final Future<void> Function() onSavePressed;
  final Future<void> Function() onBirthDatePressed;
  final Future<void> Function() onLogoutPressed;

  @override
  Widget build(BuildContext context) {
    final title = nameController.text.trim().isEmpty
        ? 'USER_TEST'
        : nameController.text.trim();

    return Column(
      children: [
        Container(
          width: 116,
          height: 116,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFE2E4E6),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: const Icon(
            Icons.account_circle_rounded,
            size: 116,
            color: Color(0xFFAEB4B8),
          ),
        ),
        const SizedBox(height: 34),
        Text(
          title.toUpperCase(),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w800,
            color: Color(0xFF4A4A4A),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ProfileActionButton(
                label: isEditing ? 'Save' : 'Edit',
                icon: isEditing ? Icons.check_rounded : Icons.edit_outlined,
                isLoading: viewModel.isLoading,
                onPressed: isEditing ? onSavePressed : onEditPressed,
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: ProfileActionButton(
                label: 'Logout',
                icon: Icons.logout_rounded,
                isLoading: viewModel.isLoading,
                onPressed: onLogoutPressed,
              ),
            ),
          ],
        ),
        if (isEditing) ...[
          const SizedBox(height: 14),
          SizedBox(
            width: 120,
            height: 42,
            child: ElevatedButton(
              onPressed: viewModel.isLoading ? null : onCancelPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFCFCFCF),
                foregroundColor: Colors.white,
                elevation: 5,
                shadowColor: Colors.black.withValues(alpha: 0.18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
        const SizedBox(height: 22),
        ProfileStatusMessage(
          errorMessage: viewModel.errorMessage,
          infoMessage: viewModel.infoMessage,
        ),
        const SizedBox(height: 96),
        LayoutBuilder(
          builder: (context, constraints) {
            final fields = [
              ProfileFieldData(
                label: 'Nome',
                controller: nameController,
                icon: Icons.badge_outlined,
              ),
              ProfileFieldData(
                label: 'Email',
                controller: emailController,
                icon: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
              ),
              ProfileFieldData(
                label: 'Nascimento',
                controller: birthDateController,
                icon: Icons.cake_outlined,
                readOnly: true,
                onTap: onBirthDatePressed,
              ),
              ProfileFieldData(
                label: 'Telefone',
                controller: phoneController,
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              ProfileFieldData(
                label: 'Preferências',
                controller: preferencesController,
                icon: Icons.tune_rounded,
              ),
            ];

            return Wrap(
              spacing: 28,
              runSpacing: 24,
              alignment: WrapAlignment.center,
              children: fields
                  .map(
                    (field) => SizedBox(
                      width: constraints.maxWidth > 300
                          ? (constraints.maxWidth - 28) / 2
                          : constraints.maxWidth,
                      child: ProfileInfoField(
                        data: field,
                        isEditing: isEditing,
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}
