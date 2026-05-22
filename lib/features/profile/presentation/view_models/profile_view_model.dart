import 'package:flutter/material.dart';
import 'package:clinic_go/features/auth/domain/auth_service.dart';
import 'package:image_picker/image_picker.dart';

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
  Map<String, dynamic> get profileMetadata => _auth.currentUserMetadata;

  String get displayName {
    final metadata = profileMetadata;
    final name = _metadataString(metadata, 'name');
    return name.isNotEmpty ? name : _metadataString(metadata, 'full_name');
  }

  String get birthDate => _metadataString(profileMetadata, 'birth_date');

  String get phone => _metadataString(profileMetadata, 'phone');

  String get preferences => _metadataString(profileMetadata, 'preferences');

  String get avatarUrl => _metadataString(profileMetadata, 'avatar_url');

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

  Future<void> updateProfile({
    required String name,
    required String email,
    required String birthDate,
    required String phone,
    required String preferences,
  }) async {
    final cleanName = name.trim();
    final cleanEmail = email.trim();
    final cleanBirthDate = birthDate.trim();
    final cleanPhone = phone.trim();
    final cleanPreferences = preferences.trim();

    if (cleanName.isEmpty) {
      _setError('Please enter your name.');
      return;
    }

    if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
      _setError('Enter a valid email.');
      return;
    }

    _setLoading(true);
    _clearMessages(notify: false);

    try {
      await _auth.updateProfile(
        email: cleanEmail,
        metadata: {
          ...profileMetadata,
          'name': cleanName,
          'birth_date': cleanBirthDate,
          'phone': cleanPhone,
          'preferences': cleanPreferences,
        },
      );
      _infoMessage = 'Profile updated successfully.';
    } on AuthServiceException catch (error) {
      _errorMessage = _profileUpdateMessageFor(error);
    } catch (_) {
      _errorMessage = 'Something went wrong while updating your profile.';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> uploadAvatar(XFile image) async {
    _setLoading(true);
    _clearMessages(notify: false);

    try {
      final bytes = await image.readAsBytes();
      final ext = image.name.split('.').last.toLowerCase();
      final url = await _auth.uploadAvatar(bytes: bytes, fileExtension: ext);

      await _auth.updateProfile(
        email: currentUserEmail ?? '',
        metadata: {...profileMetadata, 'avatar_url': url},
      );
      _infoMessage = 'Foto de perfil atualizada.';
    } catch (e, st) {
      debugPrint('uploadAvatar error: $e\n$st');
      _errorMessage = 'Erro ao atualizar a foto de perfil.';
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

  String _metadataString(Map<String, dynamic> metadata, String key) {
    final value = metadata[key];
    return value is String ? value.trim() : '';
  }

  String _profileUpdateMessageFor(AuthServiceException error) {
    return switch (error.type) {
      AuthFailureType.validation =>
        'Please check your profile details and try again.',
      AuthFailureType.network =>
        'Could not update profile. Check your internet connection.',
      AuthFailureType.unknown =>
        'Something went wrong while updating your profile.',
    };
  }
}
