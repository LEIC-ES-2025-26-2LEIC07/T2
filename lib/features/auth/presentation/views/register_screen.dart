import 'package:flutter/material.dart';
import 'package:clinic_go/core/di/service_locator.dart';
import 'package:clinic_go/core/routing/app_router.dart';
import 'package:clinic_go/core/themes/app_colors.dart';
import 'package:clinic_go/core/widgets/app_loading_button.dart';
import 'package:clinic_go/core/widgets/auth_text_field.dart';
import 'package:clinic_go/core/widgets/status_banner.dart';
import 'package:clinic_go/features/auth/domain/auth_service.dart';
import 'package:clinic_go/features/auth/presentation/view_models/sign_up_view_model.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  late final SignUpViewModel _viewModel;
  final _nameController = TextEditingController();
  final _dobController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  String? _dobIso;
  bool _obscurePassword = true;

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
    _nameController.dispose();
    _dobController.dispose();
    _phoneController.dispose();
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

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 25, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _dobController.text =
          '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      _dobIso =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    });
  }

  Future<void> _handleSignUp() async {
    FocusScope.of(context).unfocus();
    await _viewModel.signUp(
      email: _emailController.text,
      password: _passwordController.text,
      confirmPassword: _confirmController.text,
      fullName: _nameController.text,
      phone: _phoneController.text,
      birthDate: _dobIso ?? '',
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.ink),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Criar conta',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            Text(
              'Conta-nos um pouco sobre ti.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.muted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '1 DE 2',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.muted.withValues(alpha: 0.7),
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: 0.5,
                      minHeight: 4,
                      backgroundColor: AppColors.lemon.withValues(alpha: 0.15),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.lemon,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: AnimatedBuilder(
                  animation: _viewModel,
                  builder: (context, _) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _sectionLabel('PESSOAL'),
                        const SizedBox(height: 12),
                        _labeledField(
                          label: 'NOME COMPLETO',
                          controller: _nameController,
                          hint: 'ex: Maria Silva',
                        ),
                        const SizedBox(height: 12),
                        _labeledField(
                          label: 'DATA DE NASCIMENTO',
                          controller: _dobController,
                          hint: 'DD / MM / AAAA',
                          suffix: const Icon(
                            Icons.calendar_today_outlined,
                            size: 18,
                            color: Color(0xFFB0B0B0),
                          ),
                          readOnly: true,
                          onTap: _pickDate,
                        ),
                        const SizedBox(height: 12),
                        _labeledField(
                          label: 'TELEFONE',
                          controller: _phoneController,
                          hint: '+351 9XX XXX XXX',
                          keyboard: TextInputType.phone,
                          suffix: const Icon(
                            Icons.phone_outlined,
                            size: 18,
                            color: Color(0xFFB0B0B0),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _sectionLabel('ACESSO'),
                        const SizedBox(height: 12),
                        _labeledField(
                          label: 'EMAIL',
                          controller: _emailController,
                          hint: 'o.teu@email.pt',
                          keyboard: TextInputType.emailAddress,
                          suffix: const Icon(
                            Icons.mail_outline,
                            size: 18,
                            color: Color(0xFFB0B0B0),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _labeledField(
                          label: 'PASSWORD',
                          controller: _passwordController,
                          hint: 'Mínimo 8 caracteres',
                          obscure: _obscurePassword,
                          suffix: GestureDetector(
                            onTap: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                            child: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 18,
                              color: const Color(0xFFB0B0B0),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Pelo menos 8 caracteres, com letras e números.',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.muted,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _labeledField(
                          label: 'CONFIRMAR PASSWORD',
                          controller: _confirmController,
                          hint: 'Repete a password',
                          obscure: _obscurePassword,
                        ),
                        if (_viewModel.errorMessage != null) ...[
                          const SizedBox(height: 16),
                          StatusBanner(
                            message: _viewModel.errorMessage!,
                            isSuccess: false,
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(24, 8, 24, 24 + bottomInset),
              child: AnimatedBuilder(
                animation: _viewModel,
                builder: (context, _) => AppLoadingButton(
                  label: 'Concluir registo →',
                  onPressed: _handleSignUp,
                  isLoading: _viewModel.isLoading,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: AppColors.muted,
        letterSpacing: 1.4,
      ),
    );
  }

  Widget _labeledField({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboard,
    Widget? suffix,
    bool readOnly = false,
    VoidCallback? onTap,
    bool obscure = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.muted,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 6),
        AuthTextField(
          controller: controller,
          hintText: hint,
          keyboardType: keyboard,
          obscureText: obscure,
          suffixIcon: suffix,
          readOnly: readOnly,
          onTap: onTap,
        ),
      ],
    );
  }
}
