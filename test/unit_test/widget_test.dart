import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clinic_go/main.dart';
import 'package:clinic_go/ui/common/widgets/custom_search_bar.dart';
import 'package:clinic_go/ui/common/widgets/floating_bottom_nav_bar.dart';

void main() {
  group('ClinicGO', () {
    testWidgets('configures the main Material app shell', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const ClinicGO());

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));

      expect(materialApp.title, 'ClinicGO');
      expect(materialApp.debugShowCheckedModeBanner, isFalse);
      expect(materialApp.theme?.useMaterial3, isTrue);
      expect(find.byType(MainScreen), findsOneWidget);
    });
  });

  group('MainScreen', () {
    testWidgets('renders the home screen search bar', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: MainScreen()));

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(CustomSearchBar), findsOneWidget);
      expect(find.text('O que precisas?'), findsOneWidget);
    });

    testWidgets('shows the five primary navigation actions', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: MainScreen()));

      expect(find.byType(FloatingBottomNavBar), findsOneWidget);
    });

    testWidgets(
      'keeps the search field text after interacting with navigation',
      (WidgetTester tester) async {
        await tester.pumpWidget(const MaterialApp(home: MainScreen()));

        await tester.enterText(find.byType(TextField), 'treino');
        await tester.pump();

        expect(find.text('treino'), findsOneWidget);
      },
    );
  });
}
