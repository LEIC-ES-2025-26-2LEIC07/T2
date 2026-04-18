import 'package:clinic_go/features/auth/domain/auth_service.dart';

// ---------------------------------------------------------------------------
// Hand-rolled mocks
// ---------------------------------------------------------------------------

class AlwaysSuccessAuth implements AuthService {
  @override
  String? get currentUserEmail => null;

  @override
  bool get isLoggedIn => false;

  @override
  Stream<bool> get authStateChanges => const Stream.empty();

  @override
  Future<void> signIn({
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> signUp({
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> signOut() async {}

  @override
  Future<void> resetPassword(String email) async {}
}

class AlwaysFailAuth implements AuthService {
  final Object error;
  AlwaysFailAuth({required this.error});

  @override
  String? get currentUserEmail => null;

  @override
  bool get isLoggedIn => false;

  @override
  Stream<bool> get authStateChanges => const Stream.empty();

  @override
  Future<void> signIn({
    required String email,
    required String password,
  }) async => throw error;

  @override
  Future<void> signUp({
    required String email,
    required String password,
  }) async => throw error;

  @override
  Future<void> signOut() async {}

  @override
  Future<void> resetPassword(String email) async {}
}
