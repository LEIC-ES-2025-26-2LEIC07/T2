import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'package:clinic_go/data/repositories/auth_repository.dart';
import 'package:clinic_go/domain/models/user_model.dart';
import 'package:clinic_go/ui/auth/view_models/auth_view_model.dart';
import 'package:clinic_go/ui/auth/views/auth_wrapper.dart';
import 'package:clinic_go/ui/auth/views/login_view.dart';

import 'auth_wrapper_test.mocks.dart';

const _fakeUser = UserModel(id: 'u-wrap', email: 'wrap@test.com');

@GenerateMocks([AuthRepository])
void main() {
  late MockAuthRepository mockRepo;
  late StreamController<UserModel?> authStream;

  setUp(() {
    mockRepo = MockAuthRepository();
    authStream = StreamController<UserModel?>.broadcast();
    when(mockRepo.authStateChanges).thenAnswer((_) => authStream.stream);
  });

  tearDown(() => authStream.close());

  Widget buildWrapper({UserModel? currentUser}) {
    when(mockRepo.currentUser).thenReturn(currentUser);
    if (currentUser != null) {
      when(mockRepo.fetchCurrentUser(any)).thenAnswer((_) async => currentUser);
    }
    return ChangeNotifierProvider<AuthViewModel>(
      create: (_) => AuthViewModel(repo: mockRepo),
      child: const MaterialApp(
        home: AuthWrapper(authenticatedChild: Scaffold(body: Text('HOME'))),
      ),
    );
  }

  // ─── Unauthenticated ───────────────────────────────────────────────────────

  group('AuthWrapper – unauthenticated', () {
    testWidgets('shows LoginView when not authenticated', (tester) async {
      await tester.pumpWidget(buildWrapper());
      await tester.pump(); // first frame
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(LoginView), findsOneWidget);
      expect(find.text('HOME'), findsNothing);
    });

    testWidgets('shows loading indicator while auth action is pending', (
      tester,
    ) async {
      // Use a never-completing Completer to hold the signIn in loading state.
      final completer = Completer<UserModel>();
      when(
        mockRepo.signIn(
          email: anyNamed('email'),
          password: anyNamed('password'),
        ),
      ).thenAnswer((_) => completer.future);

      // _init() needs these stubs.
      when(mockRepo.currentUser).thenReturn(null);
      when(mockRepo.authStateChanges).thenAnswer((_) => authStream.stream);

      final vm = AuthViewModel(repo: mockRepo);
      await tester.pumpWidget(
        ChangeNotifierProvider<AuthViewModel>.value(
          value: vm,
          child: const MaterialApp(
            home: AuthWrapper(authenticatedChild: Scaffold(body: Text('HOME'))),
          ),
        ),
      );
      await tester.pump();

      // Trigger loading — do NOT await so the completer keeps it pending.
      // ignore: unawaited_futures
      vm.signIn(email: 'a@b.com', password: 'pass');
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Clean up.
      completer.complete(const UserModel(id: 'u', email: 'a@b.com'));
      await tester.pumpAndSettle();
    });
  });

  // ─── Authenticated ─────────────────────────────────────────────────────────

  group('AuthWrapper – authenticated', () {
    testWidgets('shows authenticated child when user is logged in', (
      tester,
    ) async {
      await tester.pumpWidget(buildWrapper(currentUser: _fakeUser));
      await tester.pumpAndSettle();

      expect(find.text('HOME'), findsOneWidget);
      expect(find.byType(LoginView), findsNothing);
    });
  });

  // ─── Stream-driven transitions ─────────────────────────────────────────────

  group('AuthWrapper – stream transitions', () {
    testWidgets('transitions to login when stream emits null', (tester) async {
      // Start unauthenticated.
      await tester.pumpWidget(buildWrapper());
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(LoginView), findsOneWidget);

      // Simulate sign-in through stream.
      when(mockRepo.fetchCurrentUser(any)).thenAnswer((_) async => _fakeUser);
      authStream.add(_fakeUser);
      await tester.pumpAndSettle();

      expect(find.text('HOME'), findsOneWidget);

      // Simulate sign-out through stream.
      authStream.add(null);
      await tester.pumpAndSettle();

      expect(find.byType(LoginView), findsOneWidget);
    });
  });
}
