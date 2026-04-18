import 'package:flutter/material.dart';
import 'package:clinic_go/features/auth/domain/auth_service.dart';

/// ViewModel for the Profile screen.
///
/// Delegates all auth side-effects to the injected [AuthService],
/// keeping this class fully testable without a live Supabase connection.
class ProfileViewModel extends ChangeNotifier {
  ProfileViewModel({required AuthService authService}) : _auth = authService;

  final AuthService _auth;

  bool _isLoading = false;
  String? _errorMessage;
  String? _infoMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get infoMessage => _infoMessage;
  String? get currentUserEmail => _auth.currentUserEmail;
  bool get isLoggedIn => _auth.isLoggedIn;

  Future<void> signIn({required String email, required String password}) async {
    final cleanEmail = email.trim();
    final cleanPassword = password.trim();

    if (cleanEmail.isEmpty || cleanPassword.isEmpty) {
      _setError('Preenche o email e a palavra-passe.');
      return;
    }

    if (!cleanEmail.contains('@')) {
      _setError('Escreve um email valido.');
      return;
    }

    _setLoading(true);
    _clearMessages(notify: false);

    try {
      await _auth.signIn(email: cleanEmail, password: cleanPassword);
      _infoMessage = 'Login feito com sucesso.';
    } catch (_) {
      _errorMessage = 'Credenciais invalidas.';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> resetPassword(String email) async {
    final cleanEmail = email.trim();

    if (cleanEmail.isEmpty) {
      _setError('Escreve o teu email para recuperar a palavra-passe.');
      return;
    }

    _setLoading(true);
    _clearMessages(notify: false);

    try {
      await _auth.resetPassword(cleanEmail);
      _infoMessage = 'Enviamos um email para redefinir a palavra-passe.';
    } catch (_) {
      _errorMessage = 'Nao foi possivel enviar o email de recuperacao.';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    _setLoading(true);
    _clearMessages(notify: false);

    try {
      await _auth.signOut();
      _infoMessage = 'Sessao terminada com sucesso.';
    } catch (_) {
      _errorMessage = 'Nao foi possivel terminar a sessao.';
    } finally {
      _setLoading(false);
    }
  }

  void clearMessages() => _clearMessages();

  void refreshSession() => notifyListeners();

  void _setError(String message) {
    _errorMessage = message;
    _infoMessage = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearMessages({bool notify = true}) {
    _errorMessage = null;
    _infoMessage = null;
    if (notify) notifyListeners();
  }
}
