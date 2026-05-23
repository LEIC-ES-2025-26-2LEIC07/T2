import 'dart:async';
import 'dart:typed_data';

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
  Map<String, dynamic> get currentUserMetadata =>
      _client.auth.currentUser?.userMetadata ?? const {};

  @override
  bool get isLoggedIn => _client.auth.currentSession != null;

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

  @override
  Future<void> updateProfile({
    required String email,
    required Map<String, dynamic> metadata,
  }) async {
    try {
      await _client.auth.updateUser(
        UserAttributes(email: email, data: metadata),
      );
    } on AuthException catch (error) {
      throw AuthServiceException(_authFailureTypeFor(error), error.message);
    } on TimeoutException {
      throw const AuthServiceException(
        AuthFailureType.network,
        'The request timed out.',
      );
    } catch (error) {
      final description = error.toString().toLowerCase();
      if (description.contains('socket') ||
          description.contains('network') ||
          description.contains('connection')) {
        throw const AuthServiceException(
          AuthFailureType.network,
          'Network connection failed.',
        );
      }

      throw AuthServiceException(AuthFailureType.unknown, error.toString());
    }
  }

  @override
  Future<String> uploadAvatar({
    required List<int> bytes,
    required String fileExtension,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AuthServiceException(
        AuthFailureType.unknown,
        'Not authenticated',
      );
    }

    final path = '$userId/avatar.$fileExtension';
    final contentType = fileExtension == 'png' ? 'image/png' : 'image/jpeg';

    await _client.storage
        .from('avatars')
        .uploadBinary(
          path,
          Uint8List.fromList(bytes),
          fileOptions: FileOptions(contentType: contentType, upsert: true),
        );

    final publicUrl = _client.storage.from('avatars').getPublicUrl(path);
    return '$publicUrl?v=${DateTime.now().millisecondsSinceEpoch}';
  }

  AuthFailureType _authFailureTypeFor(AuthException error) {
    final statusCode = int.tryParse(error.statusCode ?? '');
    if (statusCode != null && statusCode >= 400 && statusCode < 500) {
      return AuthFailureType.validation;
    }

    final message = error.message.toLowerCase();
    if (message.contains('network') ||
        message.contains('timeout') ||
        message.contains('connection')) {
      return AuthFailureType.network;
    }

    return AuthFailureType.unknown;
  }
}
