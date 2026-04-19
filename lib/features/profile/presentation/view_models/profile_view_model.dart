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
      _setError('Please fill in email and password.');
      return;
    }

    if (!cleanEmail.contains('@')) {
      _setError('Enter a valid email.');
      return;
    }

    _setLoading(true);
    _clearMessages(notify: false);

    try {
      await _auth.signIn(email: cleanEmail, password: cleanPassword);
      _infoMessage = 'Successfully logged in.';
    } catch (_) {
      _errorMessage = 'Invalid credentials.';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> resetPassword(String email) async {
    final cleanEmail = email.trim();

    if (cleanEmail.isEmpty) {
      _setError('Enter your email to recover your password.');
      return;
    }

    _setLoading(true);
    _clearMessages(notify: false);

    try {
      await _auth.resetPassword(cleanEmail);
      _infoMessage = 'We sent an email to reset your password.';
    } catch (_) {
      _errorMessage = 'Could not send recovery email.';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    _setLoading(true);
    _clearMessages(notify: false);

    try {
      await _auth.signOut();
      _infoMessage = 'Successfully signed out.';
    } catch (_) {
      _errorMessage = 'Could not sign out.';
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
