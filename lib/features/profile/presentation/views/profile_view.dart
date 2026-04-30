// ignore_for_file: unused_element, unused_element_parameter

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:clinic_go/core/themes/app_colors.dart';
import 'package:clinic_go/core/di/service_locator.dart';
import 'package:clinic_go/features/auth/domain/auth_service.dart';
import 'package:clinic_go/features/auth/presentation/views/sign_up_sheet.dart';
import 'package:clinic_go/features/profile/presentation/view_models/profile_view_model.dart';
import 'package:clinic_go/core/routing/app_router.dart';

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

  StreamSubscription<bool>? _authSubscription;

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
                      color: const Color(0xFFF8F6F0),
                      borderRadius: BorderRadius.circular(34),
                      image: const DecorationImage(
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
  const _LoggedInCard({required this.viewModel, required this.onLogoutPressed});

  final ProfileViewModel viewModel;
  final Future<void> Function() onLogoutPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.account_circle_rounded,
          size: 84,
          color: AppColors.primaryColor,
        ),
        const SizedBox(height: 18),
        const Text(
          'Signed in',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          viewModel.currentUserEmail ?? 'Utilizador autenticado',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black54,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 20),
        _StatusMessage(
          errorMessage: viewModel.errorMessage,
          infoMessage: viewModel.infoMessage ?? 'Successfully signed in.',
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: 195,
          height: 58,
          child: ElevatedButton(
            onPressed: () {Navigator.of(context).pushNamed(AppRouter.login);},         
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primaryColor,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
                side: const BorderSide(color: AppColors.primaryColor),
              ),
            ),
            child: viewModel.isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Sign out',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ],
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

class _SocialLoginButton extends StatelessWidget {
  const _SocialLoginButton({
    required this.label,
    this.icon,
    this.iconColor,
    this.customIconText,
    this.customIconColor,
  });

  final String label;
  final IconData? icon;
  final Color? iconColor;
  final String? customIconText;
  final Color? customIconColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE7E7E7),
          foregroundColor: Colors.black87,
          disabledBackgroundColor: const Color(0xFFE7E7E7),
          disabledForegroundColor: Colors.black87,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 34,
              child: Center(
                child: customIconText != null
                    ? Text(
                        customIconText!,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: customIconColor,
                        ),
                      )
                    : Icon(icon, color: iconColor, size: 30),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
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
