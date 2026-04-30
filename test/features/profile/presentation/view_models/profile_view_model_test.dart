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
          'Could not update profile. Check your internet connection.',
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
          'Please check your profile details and try again.',
        );
      },
    );
  });
}

class _ProfileAuth implements AuthService {
  _ProfileAuth({this.metadata = const {}, this.updateError});

  final Map<String, dynamic> metadata;
  final Object? updateError;

  @override
  String? get currentUserEmail => 'user@example.com';

  @override
  Map<String, dynamic> get currentUserMetadata => metadata;

  @override
  bool get isLoggedIn => true;

  @override
  Stream<bool> get authStateChanges => const Stream.empty();

  @override
  Future<void> resetPassword(String email) async {}

  @override
  Future<void> signIn({
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> signOut() async {}

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
}
