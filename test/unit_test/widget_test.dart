import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:four_u_app/main.dart';

void main() {
  group('FourUApp', () {
    testWidgets('configures the main Material app shell', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const FourUApp());

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));

      expect(materialApp.title, '4U');
      expect(materialApp.debugShowCheckedModeBanner, isFalse);
      expect(materialApp.theme?.useMaterial3, isTrue);
      expect(find.byType(HomePage), findsOneWidget);
    });
  });

  group('HomePage', () {
    testWidgets('renders the home screen search bar', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: HomePage()));

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(SafeArea), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('O que precisas?'), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('shows the five primary navigation actions', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: HomePage()));

      expect(find.byType(IconButton), findsNWidgets(5));
      expect(find.byIcon(Icons.person_outline), findsOneWidget);
      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
      expect(find.byIcon(Icons.home_outlined), findsOneWidget);
      expect(find.byIcon(Icons.calendar_today_outlined), findsOneWidget);
      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
    });

    testWidgets('keeps the search field text after interacting with navigation', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: HomePage()));

      await tester.enterText(find.byType(TextField), 'treino');
      await tester.tap(find.byIcon(Icons.home_outlined));
      await tester.pump();

      expect(find.text('treino'), findsOneWidget);
      expect(find.byType(IconButton), findsNWidgets(5));
    });
  });
}
