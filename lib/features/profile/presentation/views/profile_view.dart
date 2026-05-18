import 'dart:async';

import 'package:flutter/material.dart';
import 'package:clinic_go/core/di/service_locator.dart';
import 'package:clinic_go/core/themes/app_colors.dart';
import 'package:clinic_go/features/auth/domain/auth_service.dart';
import 'package:clinic_go/features/profile/presentation/view_models/profile_view_model.dart';
import 'package:clinic_go/features/profile/presentation/widgets/profile_widgets.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key, this.onSignOut});

  final VoidCallback? onSignOut;

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
    widget.onSignOut?.call();
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
                          ? AppColors.card.withValues(alpha: 0.96)
                          : const Color(0xFFF8F6F0),
                      borderRadius: BorderRadius.circular(
                        _viewModel.isLoggedIn ? 22 : 34,
                      ),
                      image: _viewModel.isLoggedIn
                          ? null
                          : const DecorationImage(
                              image: AssetImage(
                                'assets/images/wallpaper-paper.png',
                              ),
                              fit: BoxFit.cover,
                              opacity: 0.08,
                            ),
                    ),
                    child: _viewModel.isLoggedIn
                        ? ProfileLoggedInCard(
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
                        : ProfileLoginForm(
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
