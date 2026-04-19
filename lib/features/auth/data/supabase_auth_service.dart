import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:clinic_go/features/auth/domain/auth_service.dart';

/// Production implementation of [AuthService] backed by Supabase.
///
/// Lives in the data layer — the only file in this feature that is
/// allowed to import supabase_flutter.
class SupabaseAuthService implements AuthService {
  SupabaseAuthService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  @override
  String? get currentUserEmail => _client.auth.currentUser?.email;

  @override
  bool get isLoggedIn => _client.auth.currentUser != null;

  @override
  Stream<bool> get authStateChanges => _client.auth.onAuthStateChange.map(
    (data) => data.event == AuthChangeEvent.signedIn,
  );

  @override
  Future<void> signIn({required String email, required String password}) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  @override
  Future<void> signUp({required String email, required String password}) async {
    await _client.auth.signUp(email: email, password: password);
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  @override
  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }
}
