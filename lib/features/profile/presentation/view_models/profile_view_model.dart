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
      _setError('Preenche o email e a palavra-passe.');
      return;
    }

    if (!cleanEmail.contains('@')) {
      _setError('Introduz um email válido.');
      return;
    }

    _setLoading(true);
    _clearMessages(notify: false);

    try {
      await _auth.signIn(email: cleanEmail, password: cleanPassword);
      _infoMessage = 'Sessão iniciada com sucesso.';
    } catch (_) {
      _errorMessage = 'Credenciais inválidas.';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> resetPassword(String email) async {
    final cleanEmail = email.trim();

    if (cleanEmail.isEmpty) {
      _setError('Introduz o teu email para recuperar a palavra-passe.');
      return;
    }

    _setLoading(true);
    _clearMessages(notify: false);

    try {
      await _auth.resetPassword(cleanEmail);
      _infoMessage = 'Enviámos um email para redefinir a tua palavra-passe.';
    } catch (_) {
      _errorMessage = 'Não foi possível enviar o email de recuperação.';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    _setLoading(true);
    _clearMessages(notify: false);

    try {
      await _auth.signOut();
      _infoMessage = 'Sessão terminada com sucesso.';
    } catch (_) {
      _errorMessage = 'Não foi possível terminar a sessão.';
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
      _setError('Introduz o teu nome.');
      return;
    }

    if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
      _setError('Introduz um email válido.');
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
      _infoMessage = 'Perfil atualizado com sucesso.';
    } on AuthServiceException catch (error) {
      _errorMessage = _profileUpdateMessageFor(error);
    } catch (_) {
      _errorMessage = 'Ocorreu um erro ao atualizar o perfil.';
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
        'Verifica os dados do perfil e tenta novamente.',
      AuthFailureType.network =>
        'Não foi possível atualizar o perfil. Verifica a tua ligação à internet.',
      AuthFailureType.unknown => 'Ocorreu um erro ao atualizar o perfil.',
    };
  }
}
