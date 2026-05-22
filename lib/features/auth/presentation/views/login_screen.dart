import 'package:flutter/material.dart';
import 'package:clinic_go/core/di/service_locator.dart';
import 'package:clinic_go/core/routing/app_router.dart';
import 'package:clinic_go/core/themes/app_colors.dart';
import 'package:clinic_go/core/widgets/app_background.dart';
import 'package:clinic_go/core/widgets/app_loading_button.dart';
import 'package:clinic_go/core/widgets/auth_text_field.dart';
import 'package:clinic_go/core/widgets/status_banner.dart';
import 'package:clinic_go/features/auth/domain/auth_service.dart';
import 'package:clinic_go/features/auth/presentation/view_models/login_view_model.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.successMessage});

  final String? successMessage;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final LoginViewModel _viewModel;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _viewModel = LoginViewModel(authService: getIt<AuthService>());
    _viewModel.addListener(_onViewModelChanged);
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);
    _viewModel.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onViewModelChanged() {
    if (_viewModel.clearPassword) {
      _passwordController.clear();
      _viewModel.acknowledgePasswordClear();
    }
    if (_viewModel.success && mounted) {
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRouter.home, (_) => false);
    }
  }

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();
    await _viewModel.signIn(
      email: _emailController.text,
      password: _passwordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: AnimatedBuilder(
                animation: _viewModel,
                builder: (context, _) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _LoginHero(),
                      const SizedBox(height: 32),
                      _formCard(),
                      const SizedBox(height: 16),
                      _createAccountCard(),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _formCard() {
    final hasStatus =
        widget.successMessage != null || _viewModel.errorMessage != null;

    return Container(
      decoration: BrutalDecor.box(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthTextField(
            controller: _emailController,
            hintText: 'Email',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          AuthTextField(
            controller: _passwordController,
            hintText: 'Palavra-passe',
            obscureText: true,
          ),
          const SizedBox(height: 12),
          if (widget.successMessage != null)
            StatusBanner(message: widget.successMessage!, isSuccess: true),
          if (_viewModel.errorMessage != null)
            StatusBanner(message: _viewModel.errorMessage!, isSuccess: false),
          if (hasStatus) const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _viewModel.isLoading
                  ? null
                  : () => _viewModel.resetPassword(_emailController.text),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 32),
              ),
              child: const Text(
                'ESQUECI-ME',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.muted,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          AppLoadingButton(
            label: 'Entrar',
            onPressed: _handleLogin,
            isLoading: _viewModel.isLoading,
          ),
        ],
      ),
    );
  }

  Widget _createAccountCard() {
    return Container(
      decoration: BrutalDecor.box(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.lemon, width: 2),
            ),
            child: const Icon(
              Icons.person_outline_rounded,
              color: AppColors.lemon,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NOVO POR AQUI?',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.muted,
                    letterSpacing: 1.2,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Cria a tua conta',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.of(context).pushNamed(AppRouter.register),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: AppColors.ink,
                borderRadius: BorderRadius.circular(10),
                boxShadow: BrutalDecor.shadowSm,
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'CRIAR',
                    style: TextStyle(
                      color: AppColors.card,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      letterSpacing: 0.6,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward, color: AppColors.card, size: 14),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginHero extends StatelessWidget {
  const _LoginHero();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.lemon,
            border: BrutalDecor.border,
            borderRadius: BorderRadius.circular(18),
            boxShadow: BrutalDecor.shadow,
          ),
          child: const Icon(
            Icons.medication_rounded,
            color: AppColors.card,
            size: 36,
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'ClinicGO',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppColors.lemon,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'BEM-VINDA DE VOLTA',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.muted,
            letterSpacing: 1.4,
          ),
        ),
      ],
    );
  }
}
