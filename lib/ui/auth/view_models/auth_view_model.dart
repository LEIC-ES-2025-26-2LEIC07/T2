import 'package:flutter/foundation.dart';
import 'package:clinic_go/data/repositories/auth_repository.dart';
import 'package:clinic_go/domain/models/user_model.dart';

/// The possible states the authentication flow can be in.
enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

/// ViewModel for the authentication feature.
///
/// Consumed by [LoginView] and [AuthWrapper]. Listens to the Supabase
/// auth-state stream so the UI reacts automatically to session changes
/// (e.g. token expiry, external sign-out).
class AuthViewModel extends ChangeNotifier {
  // ---------------------------------------------------------------------------
  // Dependencies
  // ---------------------------------------------------------------------------
  final AuthRepository _repo;

  AuthViewModel({AuthRepository? repo})
    : _repo = repo ?? AuthRepository.instance {
    _init();
  }

  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------
  AuthStatus _status = AuthStatus.initial;
  UserModel? _user;
  String? _errorMessage;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;

  bool get isAuthenticated => _status == AuthStatus.authenticated;

  // ---------------------------------------------------------------------------
  // Initialisation
  // ---------------------------------------------------------------------------

  /// Seeds state from the existing session and subscribes to auth changes.
  void _init() {
    // Check if there's already a session (app restart / warm start).
    final existing = _repo.currentUser;
    if (existing != null) {
      _user = existing;
      _status = AuthStatus.authenticated;
      // Hydrate profile in background.
      _repo.fetchCurrentUser(existing).then((hydrated) {
        _user = hydrated;
        notifyListeners();
      });
    } else {
      _status = AuthStatus.unauthenticated;
    }

    // Subscribe to future auth state changes.
    _repo.authStateChanges.listen((userOrNull) {
      if (userOrNull != null) {
        _user = userOrNull;
        _status = AuthStatus.authenticated;
        // Hydrate profile in background.
        _repo.fetchCurrentUser(userOrNull).then((hydrated) {
          _user = hydrated;
          notifyListeners();
        });
      } else {
        _user = null;
        _status = AuthStatus.unauthenticated;
      }
      notifyListeners();
    });
  }

  // ---------------------------------------------------------------------------
  // Operations
  // ---------------------------------------------------------------------------

  /// Sign in with [email] and [password].
  Future<void> signIn({required String email, required String password}) async {
    _setLoading();
    try {
      _user = await _repo.signIn(email: email, password: password);
      _status = AuthStatus.authenticated;
      _errorMessage = null;
    } on AuthException catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.message;
    } finally {
      notifyListeners();
    }
  }

  /// Register a new account with optional [fullName] and [phone].
  Future<void> signUp({
    required String email,
    required String password,
    String? fullName,
    String? phone,
  }) async {
    _setLoading();
    try {
      _user = await _repo.signUp(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
      );
      _status = AuthStatus.authenticated;
      _errorMessage = null;
    } on AuthException catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.message;
    } finally {
      notifyListeners();
    }
  }

  /// Sign out the current user.
  Future<void> signOut() async {
    _setLoading();
    try {
      await _repo.signOut();
      _user = null;
      _status = AuthStatus.unauthenticated;
      _errorMessage = null;
    } on AuthException catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.message;
    } finally {
      notifyListeners();
    }
  }

  /// Clears the current error so the UI can reset.
  void clearError() {
    _errorMessage = null;
    if (_status == AuthStatus.error) {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  void _setLoading() {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
  }
}
