import 'package:supabase_flutter/supabase_flutter.dart';

/// Low-level wrapper around the Supabase Auth API.
///
/// This service owns the raw Supabase client calls. It throws
/// [AuthException] (from the Supabase SDK) on failure, which the
/// repository layer catches and converts into domain exceptions.
class SupabaseAuthService {
  // ---------------------------------------------------------------------------
  // Singleton
  // ---------------------------------------------------------------------------
  SupabaseAuthService._();
  static final SupabaseAuthService instance = SupabaseAuthService._();

  SupabaseClient get _client => Supabase.instance.client;

  // ---------------------------------------------------------------------------
  // Accessors
  // ---------------------------------------------------------------------------

  /// The currently signed-in Supabase user, or `null` if no session exists.
  User? get currentUser => _client.auth.currentUser;

  /// Stream that emits an [AuthState] every time the auth state changes
  /// (sign-in, sign-out, token refresh, etc.).
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  // ---------------------------------------------------------------------------
  // Operations
  // ---------------------------------------------------------------------------

  /// Signs in an existing user with [email] and [password].
  ///
  /// Throws [AuthException] if credentials are wrong or the network fails.
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  /// Registers a new user with [email] and [password].
  ///
  /// Optionally stores a [displayName] in `user_metadata`.
  /// Throws [AuthException] on failure.
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    return _client.auth.signUp(
      email: email,
      password: password,
      data: displayName != null ? {'display_name': displayName} : null,
    );
  }

  /// Signs out the current user and clears the local session.
  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
