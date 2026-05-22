import 'package:clinic_go/features/auth/domain/auth_service.dart';
import 'package:clinic_go/features/profile/presentation/view_models/profile_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProfileViewModel', () {
    test('safely ignores non-string metadata values', () {
      final vm = ProfileViewModel(
        authService: _ProfileAuth(
          metadata: const {
            'name': 123,
            'full_name': '  Maria Silva  ',
            'birth_date': null,
            'phone': 919999999,
            'preferences': '  Afternoon  ',
          },
        ),
      );

      expect(vm.displayName, 'Maria Silva');
      expect(vm.birthDate, '');
      expect(vm.phone, '');
      expect(vm.preferences, 'Afternoon');
    });

    test(
      'shows network-specific message when profile update fails offline',
      () async {
        final vm = ProfileViewModel(
          authService: _ProfileAuth(
            updateError: const AuthServiceException(
              AuthFailureType.network,
              'Network connection failed.',
            ),
          ),
        );

        await vm.updateProfile(
          name: 'Maria Silva',
          email: 'maria@example.com',
          birthDate: '1990-01-02',
          phone: '919999999',
          preferences: 'Afternoon',
        );

        expect(
          vm.errorMessage,
          'Não foi possível atualizar o perfil. Verifica a tua ligação à internet.',
        );
      },
    );

    test(
      'shows validation-specific message for rejected profile data',
      () async {
        final vm = ProfileViewModel(
          authService: _ProfileAuth(
            updateError: const AuthServiceException(
              AuthFailureType.validation,
              'Email already registered.',
            ),
          ),
        );

        await vm.updateProfile(
          name: 'Maria Silva',
          email: 'maria@example.com',
          birthDate: '1990-01-02',
          phone: '919999999',
          preferences: 'Afternoon',
        );

        expect(
          vm.errorMessage,
          'Verifica os dados do perfil e tenta novamente.',
        );
      },
    );
    test('shows generic message for unknown profile update failure', () async {
      final vm = ProfileViewModel(
        authService: _ProfileAuth(
          updateError: const AuthServiceException(
            AuthFailureType.unknown,
            'Unexpected failure.',
          ),
        ),
      );

      await vm.updateProfile(
        name: 'Maria Silva',
        email: 'maria@example.com',
        birthDate: '1990-01-02',
        phone: '919999999',
        preferences: 'Afternoon',
      );

      expect(
        vm.errorMessage,
        'Ocorreu um erro ao atualizar o perfil.',
      );
    });

    test('sets errorMessage when name is empty', () async {
      final vm = ProfileViewModel(authService: _ProfileAuth());

      await vm.updateProfile(
        name: '',
        email: 'maria@example.com',
        birthDate: '',
        phone: '',
        preferences: '',
      );

      expect(vm.errorMessage, 'Introduz o teu nome.');
    });

    test('sets errorMessage when email is empty', () async {
      final vm = ProfileViewModel(authService: _ProfileAuth());

      await vm.updateProfile(
        name: 'Maria',
        email: '',
        birthDate: '',
        phone: '',
        preferences: '',
      );

      expect(vm.errorMessage, 'Introduz um email válido.');
    });

    test('sets errorMessage when email has no @', () async {
      final vm = ProfileViewModel(authService: _ProfileAuth());

      await vm.updateProfile(
        name: 'Maria',
        email: 'notanemail',
        birthDate: '',
        phone: '',
        preferences: '',
      );

      expect(vm.errorMessage, 'Introduz um email válido.');
    });

    test('sets infoMessage on successful update', () async {
      final vm = ProfileViewModel(authService: _ProfileAuth());

      await vm.updateProfile(
        name: 'Maria',
        email: 'maria@example.com',
        birthDate: '',
        phone: '',
        preferences: '',
      );

      expect(vm.infoMessage, 'Perfil atualizado com sucesso.');
      expect(vm.errorMessage, isNull);
    });

    test(
      'sets errorMessage on non-AuthServiceException update error',
      () async {
        final vm = ProfileViewModel(
          authService: _ProfileAuth(updateError: Exception('crash')),
        );

        await vm.updateProfile(
          name: 'Maria',
          email: 'maria@example.com',
          birthDate: '',
          phone: '',
          preferences: '',
        );

        expect(
          vm.errorMessage,
          'Ocorreu um erro ao atualizar o perfil.',
        );
      },
    );
  });

  group('ProfileViewModel signIn', () {
    test('sets infoMessage on success', () async {
      final vm = ProfileViewModel(authService: _ProfileAuth());
      await vm.signIn(email: 'user@example.com', password: 'secret');
      expect(vm.infoMessage, 'Sessão iniciada com sucesso.');
      expect(vm.errorMessage, isNull);
    });

    test('sets errorMessage when email is empty', () async {
      final vm = ProfileViewModel(authService: _ProfileAuth());
      await vm.signIn(email: '', password: 'secret');
      expect(vm.errorMessage, isNotNull);
    });

    test('sets errorMessage when password is empty', () async {
      final vm = ProfileViewModel(authService: _ProfileAuth());
      await vm.signIn(email: 'user@example.com', password: '');
      expect(vm.errorMessage, isNotNull);
    });

    test('sets errorMessage when email has no @', () async {
      final vm = ProfileViewModel(authService: _ProfileAuth());
      await vm.signIn(email: 'notanemail', password: 'secret');
      expect(vm.errorMessage, isNotNull);
    });

    test('sets errorMessage on sign in failure', () async {
      final vm = ProfileViewModel(
        authService: _ProfileAuth(signInError: Exception('bad')),
      );
      await vm.signIn(email: 'user@example.com', password: 'wrong');
      expect(vm.errorMessage, 'Credenciais inválidas.');
    });
  });

  group('ProfileViewModel resetPassword', () {
    test('sets infoMessage on success', () async {
      final vm = ProfileViewModel(authService: _ProfileAuth());
      await vm.resetPassword('user@example.com');
      expect(vm.infoMessage, 'Enviámos um email para redefinir a tua palavra-passe.');
    });

    test('sets errorMessage when email is empty', () async {
      final vm = ProfileViewModel(authService: _ProfileAuth());
      await vm.resetPassword('');
      expect(vm.errorMessage, isNotNull);
    });

    test('sets errorMessage on failure', () async {
      final vm = ProfileViewModel(
        authService: _ProfileAuth(resetError: Exception('fail')),
      );
      await vm.resetPassword('user@example.com');
      expect(vm.errorMessage, 'Não foi possível enviar o email de recuperação.');
    });
  });

  group('ProfileViewModel signOut', () {
    test('sets infoMessage on success', () async {
      final vm = ProfileViewModel(authService: _ProfileAuth());
      await vm.signOut();
      expect(vm.infoMessage, 'Sessão terminada com sucesso.');
    });

    test('sets errorMessage on failure', () async {
      final vm = ProfileViewModel(
        authService: _ProfileAuth(signOutError: Exception('fail')),
      );
      await vm.signOut();
      expect(vm.errorMessage, 'Não foi possível terminar a sessão.');
    });
  });

  group('ProfileViewModel displayName', () {
    test('returns name when set', () {
      final vm = ProfileViewModel(
        authService: _ProfileAuth(
          metadata: const {'name': 'Alice', 'full_name': 'Alice Wonderland'},
        ),
      );
      expect(vm.displayName, 'Alice');
    });

    test('falls back to full_name when name is empty', () {
      final vm = ProfileViewModel(
        authService: _ProfileAuth(
          metadata: const {'name': '', 'full_name': 'Bob Smith'},
        ),
      );
      expect(vm.displayName, 'Bob Smith');
    });

    test('returns empty string when both name and full_name are absent', () {
      final vm = ProfileViewModel(authService: _ProfileAuth());
      expect(vm.displayName, '');
    });
  });

  group('ProfileViewModel clearMessages and refreshSession', () {
    test('clearMessages removes both error and info messages', () async {
      final vm = ProfileViewModel(
        authService: _ProfileAuth(signInError: Exception('fail')),
      );
      await vm.signIn(email: 'user@example.com', password: 'pass');
      expect(vm.errorMessage, isNotNull);

      vm.clearMessages();
      expect(vm.errorMessage, isNull);
      expect(vm.infoMessage, isNull);
    });

    test('refreshSession notifies listeners without throwing', () {
      final vm = ProfileViewModel(authService: _ProfileAuth());
      var notified = false;
      vm.addListener(() => notified = true);

      vm.refreshSession();

      expect(notified, isTrue);
    });
  });
}

class _ProfileAuth implements AuthService {
  _ProfileAuth({
    this.metadata = const {},
    this.updateError,
    this.signInError,
    this.signOutError,
    this.resetError,
  });

  final Map<String, dynamic> metadata;
  final Object? updateError;
  final Object? signInError;
  final Object? signOutError;
  final Object? resetError;

  @override
  String? get currentUserEmail => 'user@example.com';

  @override
  Map<String, dynamic> get currentUserMetadata => metadata;

  @override
  bool get isLoggedIn => true;

  @override
  Stream<bool> get authStateChanges => const Stream.empty();

  @override
  Future<void> resetPassword(String email) async {
    final error = resetError;
    if (error != null) throw error;
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    final error = signInError;
    if (error != null) throw error;
  }

  @override
  Future<void> signOut() async {
    final error = signOutError;
    if (error != null) throw error;
  }

  @override
  Future<void> signUp({
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> updateProfile({
    required String email,
    required Map<String, dynamic> metadata,
  }) async {
    final error = updateError;
    if (error != null) throw error;
  }

  @override
  Future<String> uploadAvatar({
    required List<int> bytes,
    required String fileExtension,
  }) async => '';
}
