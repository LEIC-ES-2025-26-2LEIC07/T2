import 'dart:async';

import 'package:flutter/material.dart';
import 'package:clinic_go/core/themes/app_colors.dart';
import 'package:clinic_go/core/di/service_locator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:clinic_go/features/auth/domain/auth_service.dart';
import 'package:clinic_go/features/profile/presentation/view_models/profile_view_model.dart';
import 'package:clinic_go/features/profile/presentation/widgets/profile_widgets.dart';

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
      birthDate: _viewModel.birthDate,
      phone: _viewModel.phone,
      preferences: _viewModel.preferences,
    );
    if (mounted && _viewModel.errorMessage == null) {
      setState(() => _isEditingProfile = false);
    }
  }

  void _startEditingProfile() {
    _syncProfileControllers(force: true);
    setState(() => _isEditingProfile = true);
  }

  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (image == null || !mounted) return;
    await _viewModel.uploadAvatar(image);
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
    _profileControllersSynced = true;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: AnimatedBuilder(
        animation: _viewModel,
        builder: (context, _) {
          if (_viewModel.isLoggedIn) {
            _syncProfileControllers();
          } else {
            _profileControllersSynced = false;
          }

          if (_viewModel.isLoggedIn) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 90),
              child: ProfileLoggedInCard(
                viewModel: _viewModel,
                isEditing: _isEditingProfile,
                nameController: _nameController,
                emailController: _emailController,
                onEditPressed: _startEditingProfile,
                onCancelPressed: _cancelEditingProfile,
                onSavePressed: _handleSaveProfile,
                onLogoutPressed: _handleLogout,
                onAvatarPressed: _pickAndUploadAvatar,
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Center(
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 340),
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 34,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceWarm,
                  borderRadius: const BorderRadius.all(Radius.circular(34)),
                ),
                child: ProfileLoginForm(
                  viewModel: _viewModel,
                  emailController: _emailController,
                  passwordController: _passwordController,
                  onLoginPressed: _handleLogin,
                  onForgotPasswordPressed: _handleResetPassword,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
