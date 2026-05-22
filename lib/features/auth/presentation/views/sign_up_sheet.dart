import 'package:flutter/material.dart';
import 'package:clinic_go/core/di/service_locator.dart';
import 'package:clinic_go/core/routing/app_router.dart';
import 'package:clinic_go/core/widgets/app_loading_button.dart';
import 'package:clinic_go/core/widgets/auth_error_box.dart';
import 'package:clinic_go/core/widgets/auth_text_field.dart';
import 'package:clinic_go/features/auth/domain/auth_service.dart';
import 'package:clinic_go/features/auth/presentation/view_models/sign_up_view_model.dart';

/// Shows a modal bottom sheet with an account creation form.
///
/// Call [SignUpSheet.show] from any widget; no need to navigate.
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
      decoration: const BoxDecoration(
        color: Color(0xFFF8F6F0),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 28, 24, 24 + bottomInset),
        child: AnimatedBuilder(
          animation: _viewModel,
          builder: (context, _) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDDDDDD),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    'Criar conta',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Regista-te para começar a usar o ClinicGO.',
                    style: TextStyle(color: Color(0xFF8F8F8F)),
                  ),
                  const SizedBox(height: 24),

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
                  AuthTextField(
                    controller: _confirmController,
                    hintText: 'Confirmar palavra-passe',
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),

                  if (_viewModel.errorMessage != null) ...[
                    AuthErrorBox(message: _viewModel.errorMessage!),
                    const SizedBox(height: 16),
                  ],

                  AppLoadingButton(
                    label: 'Criar conta',
                    onPressed: _handleSignUp,
                    isLoading: _viewModel.isLoading,
                  ),
                  const SizedBox(height: 12),

                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Já tens uma conta',
                      style: TextStyle(
                        color: Color(0xFF7F7F7F),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ), // Column
            ); // SingleChildScrollView
          },
        ),
      ),
    );
  }
}
