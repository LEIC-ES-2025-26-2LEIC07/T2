import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:clinic_go/features/auth/domain/auth_service.dart';

/// ViewModel for the account-creation form.
///
/// Mirrors the shape of [LoginViewModel] so the sign-up sheet can follow
/// exactly the same patterns and be tested without Supabase.
class SignUpViewModel extends ChangeNotifier {
  SignUpViewModel({required AuthService authService}) : _auth = authService;

  final AuthService _auth;

  bool _isLoading = false;
  String? _errorMessage;
  bool _success = false;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// True after a successful sign-up. The view should close the sheet and
  /// show a confirmation message when this flips to true.
  bool get success => _success;

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  Future<void> signUp({
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    final cleanEmail = email.trim();
    final cleanPassword = password.trim();

    if (cleanEmail.isEmpty || cleanPassword.isEmpty) {
      _setError('Preenche o email e a palavra-passe.');
      return;
    }

    if (!cleanEmail.contains('@')) {
      _setError('Escreve um email válido.');
      return;
    }

    if (cleanPassword.length < 6) {
      _setError('A palavra-passe deve ter pelo menos 6 caracteres.');
      return;
    }

    if (cleanPassword != confirmPassword.trim()) {
      _setError('As palavras-passe não coincidem.');
      return;
    }

    _setLoading(true);
    _clearError(notify: false);

    try {
      await _auth.signUp(email: cleanEmail, password: cleanPassword);
      _success = true;
      notifyListeners();
    } on AuthException catch (e) {
      _setError(_friendlyAuthError(e.message));
    } catch (_) {
      _setError('Não foi possível criar a conta. Tenta outra vez.');
    } finally {
      _setLoading(false);
    }
  }

  void clearError() => _clearError();

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _friendlyAuthError(String supabaseMessage) {
    final msg = supabaseMessage.toLowerCase();
    if (msg.contains('already registered') || msg.contains('already in use')) {
      return 'Este email já está registado.';
    }
    if (msg.contains('password')) {
      return 'A palavra-passe não cumpre os requisitos mínimos.';
    }
    return 'Não foi possível criar a conta. Tenta outra vez.';
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
