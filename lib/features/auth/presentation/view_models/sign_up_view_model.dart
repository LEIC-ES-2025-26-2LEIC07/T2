import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:clinic_go/features/auth/domain/auth_service.dart';

class SignUpViewModel extends ChangeNotifier {
  SignUpViewModel({required AuthService authService}) : _auth = authService;

  final AuthService _auth;

  bool _isLoading = false;
  String? _errorMessage;
  bool _success = false;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get success => _success;

  Future<void> signUp({
    required String email,
    required String password,
    required String confirmPassword,
    String fullName = '',
    String phone = '',
    String birthDate = '',
  }) async {
    final cleanEmail = email.trim();
    final cleanPassword = password.trim();
    final cleanName = fullName.trim();

    if (cleanName.isEmpty) {
      _setError('Preenche o teu nome completo.');
      return;
    }

    if (cleanEmail.isEmpty || cleanPassword.isEmpty) {
      _setError('Preenche o email e a password.');
      return;
    }

    if (!cleanEmail.contains('@')) {
      _setError('Introduz um email válido.');
      return;
    }

    if (cleanPassword.length < 8) {
      _setError('A password tem de ter pelo menos 8 caracteres.');
      return;
    }

    if (cleanPassword != confirmPassword.trim()) {
      _setError('As passwords não coincidem.');
      return;
    }

    _setLoading(true);
    _clearError(notify: false);

    try {
      await _auth.signUp(email: cleanEmail, password: cleanPassword);

      final metadata = <String, dynamic>{
        'full_name': cleanName,
        if (phone.trim().isNotEmpty) 'phone': phone.trim(),
        if (birthDate.isNotEmpty) 'birth_date': birthDate,
      };
      try {
        await _auth.updateProfile(email: cleanEmail, metadata: metadata);
      } catch (_) {}

      _success = true;
      notifyListeners();
    } on AuthException catch (e) {
      _setError(_friendlyAuthError(e.message));
    } catch (_) {
      _setError('Não foi possível criar a conta. Tenta novamente.');
    } finally {
      _setLoading(false);
    }
  }

  void clearError() => _clearError();

  String _friendlyAuthError(String supabaseMessage) {
    final msg = supabaseMessage.toLowerCase();
    if (msg.contains('already registered') || msg.contains('already in use')) {
      return 'Este email já está registado.';
    }
    if (msg.contains('password')) {
      return 'A password não cumpre os requisitos mínimos.';
    }
    return 'Não foi possível criar a conta. Tenta novamente.';
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError({bool notify = true}) {
    _errorMessage = null;
    if (notify) notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
