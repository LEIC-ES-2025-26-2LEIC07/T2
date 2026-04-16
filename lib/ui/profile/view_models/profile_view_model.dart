import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileViewModel extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isLoading = false;
  String? _errorMessage;
  String? _infoMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get infoMessage => _infoMessage;
  User? get currentUser => _supabase.auth.currentUser;
  bool get isLoggedIn => currentUser != null;

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
      await _supabase.auth.signInWithPassword(
        email: cleanEmail,
        password: cleanPassword,
      );

      _infoMessage = 'Login feito com sucesso.';
    } on AuthException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'Nao foi possivel entrar. Tenta outra vez.';
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
      await _supabase.auth.resetPasswordForEmail(cleanEmail);
      _infoMessage = 'Enviamos um email para redefinir a palavra-passe.';
    } on AuthException catch (error) {
      _errorMessage = error.message;
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
      await _supabase.auth.signOut();
      _infoMessage = 'Sessao terminada com sucesso.';
    } on AuthException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'Nao foi possivel terminar a sessao.';
    } finally {
      _setLoading(false);
    }
  }

  void clearMessages() {
    _clearMessages();
  }

  void refreshSession() {
    notifyListeners();
  }

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

    if (notify) {
      notifyListeners();
    }
  }
}
