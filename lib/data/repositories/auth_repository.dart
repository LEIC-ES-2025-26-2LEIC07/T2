import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:clinic_go/data/services/supabase_auth_service.dart';
import 'package:clinic_go/domain/models/user_model.dart';

/// Typed exception produced by [AuthRepository].
class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => 'AuthException: $message';
}

/// Converts raw Supabase auth responses + profile rows into domain [UserModel]s.
///
/// All public methods throw [AuthException] on failure — the ViewModel never
/// deals with Supabase SDK types directly.
class AuthRepository {
  // ---------------------------------------------------------------------------
  // Singleton / DI
  // ---------------------------------------------------------------------------
  AuthRepository._();
  static final AuthRepository instance = AuthRepository._();

  final SupabaseAuthService _service = SupabaseAuthService.instance;
  SupabaseClient get _client => Supabase.instance.client;

  // ---------------------------------------------------------------------------
  // Accessors
  // ---------------------------------------------------------------------------

  /// The currently authenticated user, or `null` if signed out.
  ///
  /// Note: profile fields won't be populated here; call [fetchCurrentUser] for
  /// a fully hydrated model.
  UserModel? get currentUser {
    final user = _service.currentUser;
    return user != null ? UserModel.fromSupabaseUser(user) : null;
  }

  /// Stream of nullable [UserModel] — emits `null` on sign-out.
  ///
  /// Profile fields are NOT included; subscribe only for auth-state routing.
  Stream<UserModel?> get authStateChanges {
    return _service.authStateChanges.map((state) {
      final user = state.session?.user;
      return user != null ? UserModel.fromSupabaseUser(user) : null;
    });
  }

  // ---------------------------------------------------------------------------
  // Hydration
  // ---------------------------------------------------------------------------

  /// Fetches [user] merged with their `profiles` row.
  ///
  /// Returns a model with `null` profile fields if no profile row exists yet.
  Future<UserModel> fetchCurrentUser(UserModel user) async {
    try {
      final data = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (data == null) return user;
      return user.copyWithProfile(data);
    } catch (_) {
      // Non-critical — return base user without profile fields.
      return user;
    }
  }

  // ---------------------------------------------------------------------------
  // Operations
  // ---------------------------------------------------------------------------

  /// Sign in with [email] + [password].
  ///
  /// Returns a fully hydrated [UserModel] (auth + profile).
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _service.signInWithEmail(
        email: email,
        password: password,
      );
      final user = response.user;
      if (user == null) {
        throw const AuthException(
          'Sign-in succeeded but no user was returned.',
        );
      }
      final base = UserModel.fromSupabaseUser(user);
      return fetchCurrentUser(base);
    } on AuthException {
      rethrow;
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException(
        _friendlyMessage('An unexpected error occurred. Please try again.'),
      );
    }
  }

  /// Register a new account.
  ///
  /// Creates the `profiles` row with [fullName] and [phone] after sign-up.
  /// Returns a fully hydrated [UserModel].
  Future<UserModel> signUp({
    required String email,
    required String password,
    String? fullName,
    String? phone,
  }) async {
    try {
      final response = await _service.signUp(email: email, password: password);
      final user = response.user;
      if (user == null) {
        throw const AuthException(
          'Sign-up succeeded but no user was returned.',
        );
      }

      // Insert a profile row (the user's id mirrors auth.users.id).
      if (fullName != null || phone != null) {
        await _client.from('profiles').upsert({
          'id': user.id,
          'full_name': ?fullName,
          'phone': ?phone,
        });
      }

      final base = UserModel.fromSupabaseUser(user);
      return fetchCurrentUser(base);
    } on AuthException {
      rethrow;
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException(
        _friendlyMessage('An unexpected error occurred. Please try again.'),
      );
    }
  }

  /// Sign out the current user.
  Future<void> signOut() async {
    try {
      await _service.signOut();
    } catch (_) {
      throw const AuthException('Failed to sign out. Please try again.');
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _friendlyMessage(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('invalid login')) {
      return 'Email ou palavra-passe incorretos.';
    }
    if (lower.contains('email not confirmed')) {
      return 'Por favor confirma o teu email antes de entrar.';
    }
    if (lower.contains('user already registered')) {
      return 'Já existe uma conta com este email.';
    }
    if (lower.contains('password should be')) {
      return 'A palavra-passe deve ter pelo menos 6 caracteres.';
    }
    if (lower.contains('network')) {
      return 'Sem ligação à internet. Verifica a tua rede.';
    }
    return raw;
  }
}
