import 'package:flutter/material.dart';
import 'package:clinic_go/core/di/service_locator.dart';
import 'package:clinic_go/core/routing/app_router.dart';
import 'package:clinic_go/core/themes/app_colors.dart';
import 'package:clinic_go/core/widgets/app_loading_button.dart';
import 'package:clinic_go/core/widgets/auth_text_field.dart';
import 'package:clinic_go/core/widgets/status_banner.dart';
import 'package:clinic_go/features/auth/domain/auth_service.dart';
import 'package:clinic_go/features/auth/presentation/view_models/sign_up_view_model.dart';

/// Modal bottom sheet com o formulário de criação de conta.
///
/// Chamar via [SignUpSheet.show] a partir de qualquer widget.
class SignUpSheet extends StatefulWidget {
  const SignUpSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SignUpSheet(),
    );
  }

  @override
  State<SignUpSheet> createState() => _SignUpSheetState();
}

class _SignUpSheetState extends State<SignUpSheet> {
  late final SignUpViewModel _viewModel;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _viewModel = SignUpViewModel(authService: getIt<AuthService>());
    _viewModel.addListener(_onViewModelChanged);
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);
    _viewModel.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _onViewModelChanged() {
    if (_viewModel.success && mounted) {
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRouter.home, (_) => false);
    }
  }

  Future<void> _handleSignUp() async {
    FocusScope.of(context).unfocus();
    await _viewModel.signUp(
      email: _emailController.text,
      password: _passwordController.text,
      confirmPassword: _confirmController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: const EdgeInsets.only(top: 60),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: BrutalDecor.border,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + bottomInset),
        child: AnimatedBuilder(
          animation: _viewModel,
          builder: (context, _) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.muted.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Criar conta',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'JUNTA-TE À CLINICGO',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.muted,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
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
                          hintText: 'Password',
                          obscureText: true,
                        ),
                        const SizedBox(height: 12),
                        AuthTextField(
                          controller: _confirmController,
                          hintText: 'Confirmar password',
                          obscureText: true,
                        ),
                        if (_viewModel.errorMessage != null) ...[
                          const SizedBox(height: 12),
                          StatusBanner(
                            message: _viewModel.errorMessage!,
                            isSuccess: false,
                          ),
                        ],
                        const SizedBox(height: 16),
                        AppLoadingButton(
                          label: 'Criar conta',
                          onPressed: _handleSignUp,
                          isLoading: _viewModel.isLoading,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Já tenho conta',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
