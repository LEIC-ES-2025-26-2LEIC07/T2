/// Abstract auth contract — keeps ViewModels testable without Supabase.
///
/// Lives in the domain layer so nothing here imports infrastructure packages.
abstract class AuthService {
  /// The currently authenticated user's email, or null when unauthenticated.
  String? get currentUserEmail;

  /// Convenience check: true when a user session is active.
  bool get isLoggedIn;

  /// Sign in with email + password.
  /// Throws on invalid credentials.
  Future<void> signIn({required String email, required String password});

  /// Sign out the current user.
  Future<void> signOut();

  /// Send a password-reset e-mail to [email].
  Future<void> resetPassword(String email);
}
