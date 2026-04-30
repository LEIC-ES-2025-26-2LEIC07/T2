import 'dart:async';

import 'package:flutter/material.dart';
import 'package:clinic_go/core/themes/app_colors.dart';
import 'package:clinic_go/core/di/service_locator.dart';
import 'package:clinic_go/features/auth/domain/auth_service.dart';
import 'package:clinic_go/features/auth/presentation/views/sign_up_sheet.dart';
import 'package:clinic_go/features/profile/presentation/view_models/profile_view_model.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final ProfileViewModel _viewModel = ProfileViewModel(
    authService: getIt<AuthService>(),
  );
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _preferencesController = TextEditingController();

  StreamSubscription<bool>? _authSubscription;
  bool _isEditingProfile = false;
  bool _profileControllersSynced = false;

  @override
  void initState() {
    super.initState();
    _authSubscription = getIt<AuthService>().authStateChanges.listen((_) {
      if (mounted) {
        _viewModel.refreshSession();
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _birthDateController.dispose();
    _phoneController.dispose();
    _preferencesController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();

    await _viewModel.signIn(
      email: _emailController.text,
      password: _passwordController.text,
    );
  }

  Future<void> _handleResetPassword() async {
    FocusScope.of(context).unfocus();
    await _viewModel.resetPassword(_emailController.text);
  }

  Future<void> _handleLogout() async {
    await _viewModel.signOut();
  }

  Future<void> _handleSaveProfile() async {
    FocusScope.of(context).unfocus();

    await _viewModel.updateProfile(
      name: _nameController.text,
      email: _emailController.text,
      birthDate: _birthDateController.text,
      phone: _phoneController.text,
      preferences: _preferencesController.text,
    );

    if (mounted && _viewModel.errorMessage == null) {
      setState(() => _isEditingProfile = false);
    }
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    DateTime initialDate = DateTime(now.year - 25, now.month, now.day);

    final savedDate = DateTime.tryParse(_birthDateController.text);
    if (savedDate != null) {
      initialDate = savedDate;
    }

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: now,
    );

    if (pickedDate == null) return;

    _birthDateController.text =
        '${pickedDate.year.toString().padLeft(4, '0')}-'
        '${pickedDate.month.toString().padLeft(2, '0')}-'
        '${pickedDate.day.toString().padLeft(2, '0')}';
  }

  void _startEditingProfile() {
    _syncProfileControllers(force: true);
    setState(() => _isEditingProfile = true);
  }

  void _cancelEditingProfile() {
    _syncProfileControllers(force: true);
    _viewModel.clearMessages();
    setState(() => _isEditingProfile = false);
  }

  void _syncProfileControllers({bool force = false}) {
    if (!_viewModel.isLoggedIn || (_isEditingProfile && !force)) return;
    if (_profileControllersSynced && !force) return;

    _nameController.text = _viewModel.displayName;
    _emailController.text = _viewModel.currentUserEmail ?? '';
    _birthDateController.text = _viewModel.birthDate;
    _phoneController.text = _viewModel.phone;
    _preferencesController.text = _viewModel.preferences;
    _profileControllersSynced = true;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          margin: const EdgeInsets.only(bottom: 90),
          child: Center(
            child: AnimatedBuilder(
              animation: _viewModel,
              builder: (context, _) {
                if (_viewModel.isLoggedIn) {
                  _syncProfileControllers();
                } else {
                  _profileControllersSynced = false;
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 20,
                  ),
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 340),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 34,
                    ),
                    decoration: BoxDecoration(
                      color: _viewModel.isLoggedIn
                          ? Colors.white.withValues(alpha: 0.96)
                          : const Color(0xFFF8F6F0),
                      borderRadius: BorderRadius.circular(
                        _viewModel.isLoggedIn ? 22 : 34,
                      ),
                      image: _viewModel.isLoggedIn
                          ? null
                          : const DecorationImage(
                              image: AssetImage(
                                'assets/images/background_topography.png',
                              ),
                              fit: BoxFit.cover,
                              opacity: 0.08,
                            ),
                    ),
                    child: _viewModel.isLoggedIn
                        ? _LoggedInCard(
                            viewModel: _viewModel,
                            isEditing: _isEditingProfile,
                            nameController: _nameController,
                            emailController: _emailController,
                            birthDateController: _birthDateController,
                            phoneController: _phoneController,
                            preferencesController: _preferencesController,
                            onEditPressed: _startEditingProfile,
                            onCancelPressed: _cancelEditingProfile,
                            onSavePressed: _handleSaveProfile,
                            onBirthDatePressed: _pickBirthDate,
                            onLogoutPressed: _handleLogout,
                          )
                        : _LoginForm(
                            viewModel: _viewModel,
                            emailController: _emailController,
                            passwordController: _passwordController,
                            onLoginPressed: _handleLogin,
                            onForgotPasswordPressed: _handleResetPassword,
                          ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginForm extends StatelessWidget {
  const _LoginForm({
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
        const _LoginDivider(),
        const SizedBox(height: 24),
        _LoginTextField(
          controller: emailController,
          hintText: 'Email',
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 12),
        _LoginTextField(
          controller: passwordController,
          hintText: 'Password',
          obscureText: true,
        ),
        const SizedBox(height: 16),
        _StatusMessage(
          errorMessage: viewModel.errorMessage,
          infoMessage: viewModel.infoMessage,
        ),
        const SizedBox(height: 6),
        _ForgotPasswordText(
          isLoading: viewModel.isLoading,
          onPressed: onForgotPasswordPressed,
        ),
        const SizedBox(height: 28),
        _ContinueButton(
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

class _LoggedInCard extends StatelessWidget {
  const _LoggedInCard({
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
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w800,
            color: Color(0xFF4A4A4A),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _ProfileActionButton(
                label: isEditing ? 'Save' : 'Edit',
                icon: isEditing ? Icons.check_rounded : Icons.edit_outlined,
                isLoading: viewModel.isLoading,
                onPressed: isEditing ? onSavePressed : onEditPressed,
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: _ProfileActionButton(
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
        _StatusMessage(
          errorMessage: viewModel.errorMessage,
          infoMessage: viewModel.infoMessage,
        ),
        const SizedBox(height: 96),
        LayoutBuilder(
          builder: (context, constraints) {
            final fields = [
              _ProfileFieldData(
                label: 'Nome',
                controller: nameController,
                icon: Icons.badge_outlined,
              ),
              _ProfileFieldData(
                label: 'Email',
                controller: emailController,
                icon: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
              ),
              _ProfileFieldData(
                label: 'Nascimento',
                controller: birthDateController,
                icon: Icons.cake_outlined,
                readOnly: true,
                onTap: onBirthDatePressed,
              ),
              _ProfileFieldData(
                label: 'Telefone',
                controller: phoneController,
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              _ProfileFieldData(
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
                      child: _ProfileInfoField(
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

class _ProfileActionButton extends StatelessWidget {
  const _ProfileActionButton({
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

class _ProfileFieldData {
  const _ProfileFieldData({
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

class _ProfileInfoField extends StatelessWidget {
  const _ProfileInfoField({required this.data, required this.isEditing});

  final _ProfileFieldData data;
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

class _StatusMessage extends StatelessWidget {
  const _StatusMessage({required this.errorMessage, required this.infoMessage});

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

class _LoginDivider extends StatelessWidget {
  const _LoginDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
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

class _LoginTextField extends StatelessWidget {
  const _LoginTextField({
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

class _ForgotPasswordText extends StatelessWidget {
  const _ForgotPasswordText({required this.isLoading, required this.onPressed});

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

class _ContinueButton extends StatelessWidget {
  const _ContinueButton({required this.isLoading, required this.onPressed});

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
