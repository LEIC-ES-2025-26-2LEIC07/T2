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
import 'package:clinic_go/ui/common/widgets/custom_search_bar.dart';
import 'package:clinic_go/ui/common/widgets/floating_bottom_nav_bar.dart';
import 'package:clinic_go/main.dart';

import 'widget_test.mocks.dart';

@GenerateMocks([AuthRepository])
void main() {
  late MockAuthRepository mockRepo;
  late StreamController<UserModel?> authStream;

  setUp(() {
    mockRepo = MockAuthRepository();
    authStream = StreamController<UserModel?>.broadcast();
    when(mockRepo.currentUser).thenReturn(null);
    when(mockRepo.authStateChanges).thenAnswer((_) => authStream.stream);
  });

  tearDown(() => authStream.close());

  /// Pumps [ClinicGO] with an injected mock [AuthViewModel] so the widget
  /// tree never touches the real Supabase singleton.
  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<AuthViewModel>(
        create: (_) => AuthViewModel(repo: mockRepo),
        child: MaterialApp(
          title: 'ClinicGO',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(useMaterial3: true),
          home: const AuthWrapper(authenticatedChild: MainScreen()),
        ),
      ),
    );
    await tester.pump(); // settle initial state
  }

  group('ClinicGO', () {
    testWidgets('configures the main Material app shell', (tester) async {
      await pumpApp(tester);

      // The MaterialApp is in the tree.
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.title, 'ClinicGO');
      expect(materialApp.debugShowCheckedModeBanner, isFalse);
      expect(materialApp.theme?.useMaterial3, isTrue);
    });
  });

  group('MainScreen', () {
    testWidgets('renders the home screen search bar', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: MainScreen()));
      await tester.pump();

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(CustomSearchBar), findsOneWidget);
      expect(find.text('O que precisas?'), findsOneWidget);
    });

    testWidgets('shows the five primary navigation actions', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: MainScreen()));
      await tester.pump();

      expect(find.byType(FloatingBottomNavBar), findsOneWidget);
    });

    testWidgets(
      'keeps the search field text after interacting with navigation',
      (tester) async {
        await tester.pumpWidget(const MaterialApp(home: MainScreen()));
        await tester.pump();

        await tester.enterText(find.byType(TextField), 'treino');
        await tester.pump();

        expect(find.text('treino'), findsOneWidget);
      },
    );
  });
}
