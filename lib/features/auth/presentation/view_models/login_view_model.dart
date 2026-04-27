import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:clinic_go/features/auth/domain/auth_service.dart';

/// ViewModel for the login form inside [ProfileView].
///
/// Exposes [isLoading], [errorMessage], and [clearPassword] so the view
/// can react without holding any business logic itself.
class LoginViewModel extends ChangeNotifier {
  LoginViewModel({required AuthService authService}) : _auth = authService;

  final AuthService _auth;

  bool _isLoading = false;
  String? _errorMessage;
  bool _success = false;

  /// Whether a network request is in flight.
  bool get isLoading => _isLoading;

  /// Non-null when the last sign-in attempt failed.
  /// Null on success or before any attempt.
  String? get errorMessage => _errorMessage;

  /// True after a successful sign-in.
  bool get success => _success;

  /// True once after a failed sign-in; the view must clear the password
  /// field when it observes this, then call [acknowledgePasswordClear].
  bool _clearPassword = false;
  bool get clearPassword => _clearPassword;

  /// Called by the view after it has cleared the password field.
  void acknowledgePasswordClear() {
    _clearPassword = false;
    // No notifyListeners — this is a one-shot handshake.
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  /// Attempt sign-in with [email] and [password].
  ///
  /// On [AuthException] the error surfaced to the UI is always
  /// **'Credenciais inválidas'**, keeping internal Supabase messages hidden.
  Future<void> signIn({required String email, required String password}) async {
    final cleanEmail = email.trim();
    final cleanPassword = password.trim();

    // Local validation first — no network call needed.
    if (cleanEmail.isEmpty || cleanPassword.isEmpty) {
      _setError('Please fill in email and password.');
      return;
    }

    if (!cleanEmail.contains('@')) {
      _setError('Enter a valid email.');
      return;
    }

    _setLoading(true);
    _clearError(notify: false);

    try {
      await _auth.signIn(email: cleanEmail, password: cleanPassword);
      _success = true;
      _clearError();
    } on AuthException {
      // Always surface a generic message to avoid leaking Supabase internals.
      _errorMessage = 'Invalid credentials';
      _clearPassword = true;
      notifyListeners();
    } catch (_) {
      _errorMessage = 'Could not sign in. Please try again.';
      _clearPassword = true;
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  /// Send a password-reset e-mail.
  Future<void> resetPassword(String email) async {
    final cleanEmail = email.trim();

    if (cleanEmail.isEmpty) {
      _setError('Enter your email to recover your password.');
      return;
    }

    _setLoading(true);
    _clearError(notify: false);

    try {
      await _auth.resetPassword(cleanEmail);
      // Info message is handled by ProfileViewModel; here we just clear errors.
      _clearError();
    } on AuthException {
      _errorMessage = 'Could not send recovery email.';
      notifyListeners();
    } catch (_) {
      _errorMessage = 'Could not send recovery email.';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  /// Dismiss any displayed error message.
  void clearError() => _clearError();

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  void _setError(String message) {
    _errorMessage = message;
    _clearPassword = false;
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
