/// Abstract auth contract — keeps ViewModels testable without Supabase.
///
/// Lives in the domain layer so nothing here imports infrastructure packages.
abstract class AuthService {
  /// The currently authenticated user's email, or null when unauthenticated.
  String? get currentUserEmail;

  /// Convenience check: true when a user session is active.
  bool get isLoggedIn;

  /// Emits `true` on sign-in and `false` on sign-out.
  ///
  /// Widgets that need to react to session changes should subscribe here
  /// rather than using `Supabase.instance` directly so the dependency can
  /// be mocked in tests.
  Stream<bool> get authStateChanges;

  /// Sign in with email + password.
  /// Throws on invalid credentials.
  Future<void> signIn({required String email, required String password});

  /// Create a new account with email + password.
  /// Throws [AuthException] if the email is already in use or the password
  /// does not meet Supabase requirements.
  Future<void> signUp({required String email, required String password});

  /// Sign out the current user.
  Future<void> signOut();

  /// Send a password-reset e-mail to [email].
  Future<void> resetPassword(String email);
}
